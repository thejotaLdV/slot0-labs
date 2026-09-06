// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {LendingPool} from "../../src/governance-economics/target/LendingPool.sol";
import {LendingPoolFixed} from "../../src/governance-economics/mitigations/LendingPoolFixed.sol";

contract GovernanceEconomics02Test is Test {
    MockERC20 token;
    LendingPool pool;

    address attacker = makeAddr("attacker");
    address otherDepositor = makeAddr("otherDepositor");
    address defaultingBorrower = makeAddr("defaultingBorrower");

    function setUp() public {
        token = new MockERC20("TOKEN", "TOK");
        pool = new LendingPool(address(token));

        // otherDepositor aporta el 90% del pool, attacker el 10%
        token.mint(otherDepositor, 90_000e18);
        vm.startPrank(otherDepositor);
        token.approve(address(pool), 90_000e18);
        pool.deposit(90_000e18);
        vm.stopPrank();

        token.mint(attacker, 10_000e18);
        vm.startPrank(attacker);
        token.approve(address(pool), 10_000e18);
        pool.deposit(10_000e18);
        vm.stopPrank();

        // impago simulado: un prestamo de 40.000e18 que nunca se devuelve.
        // totalAssets sigue en 100.000e18 (nadie llamo a writeOffBadDebt),
        // pero el TOKEN real del pool ya bajo a 60.000e18
        vm.prank(defaultingBorrower);
        pool.borrow(40_000e18);
    }

    /// @dev Traza exacta de la web: totalAssets=100.000e18 (sin corregir),
    ///      balance real=60.000e18, attacker tiene 10.000e18 shares (10%).
    ///      redeem() calcula sobre el precio "de antes" del impago:
    ///      10.000e18*100.000e18/100.000e18 = 10.000e18 -- y como el balance
    ///      real (60.000e18) alcanza para cubrirlo, no revierte. Con
    ///      contabilidad honesta le correspondian 10.000e18*60.000e18/100.000e18
    ///      = 6.000e18: extrajo 4.000e18 de mas, a costa de otherDepositor.
    function test_exploit_staleAccountingRace() public {
        assertEq(pool.totalAssets(), 100_000e18);
        assertEq(token.balanceOf(address(pool)), 60_000e18);

        uint256 attackerShares = pool.sharesOf(attacker);
        assertEq(attackerShares, 10_000e18);

        uint256 fairValue = (attackerShares * 60_000e18) / 100_000e18; // 6.000e18

        vm.prank(attacker);
        uint256 received = pool.redeem(attackerShares);

        assertEq(received, 10_000e18); // valor "de antes" del impago
        assertGt(received, fairValue); // 10.000e18 > 6.000e18 -- extrajo de mas
    }

    /// @dev Fixture propia para esta mitigación: attacker tiene el 60% del
    ///      pool, y un impago de 70.000e18 deja el balance real en solo
    ///      30.000e18. Sin el fix, pedir el valor "prometido" de sus 60.000e18
    ///      shares (60.000e18) revertiría directamente (el pool no tiene
    ///      tanto TOKEN real). Con el fix, el importe se recorta al balance
    ///      disponible (30.000e18) en vez de revertir por completo.
    function test_mitigation_capsRedemptionAtAvailableBalance() public {
        MockERC20 token2 = new MockERC20("TOKEN2", "TOK2");
        LendingPoolFixed poolFixed = new LendingPoolFixed(address(token2));

        address bigDepositor = makeAddr("bigDepositor");
        token2.mint(attacker, 60_000e18);
        token2.mint(bigDepositor, 40_000e18);

        vm.startPrank(attacker);
        token2.approve(address(poolFixed), 60_000e18);
        poolFixed.deposit(60_000e18);
        vm.stopPrank();

        vm.startPrank(bigDepositor);
        token2.approve(address(poolFixed), 40_000e18);
        poolFixed.deposit(40_000e18);
        vm.stopPrank();

        vm.prank(defaultingBorrower);
        poolFixed.borrow(70_000e18);

        assertEq(token2.balanceOf(address(poolFixed)), 30_000e18, "solo queda el 30% real tras el impago");

        vm.prank(attacker);
        uint256 received = poolFixed.redeem(60_000e18);

        assertEq(received, 30_000e18, "recortado al balance real, no a los 60.000e18 prometidos");
        assertEq(token2.balanceOf(address(poolFixed)), 0, "el pool queda vacio, pero sin revertir por completo");
    }
}
