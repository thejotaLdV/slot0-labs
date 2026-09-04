// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockPriceFeed} from "../mocks/MockPriceFeed.sol";
import {SimpleAMM} from "../../src/oracle-manipulation/target/SimpleAMM.sol";
import {LendingPool} from "../../src/oracle-manipulation/target/LendingPool.sol";
import {LendingPoolFixed} from "../../src/oracle-manipulation/mitigations/LendingPoolFixed.sol";
import {OracleManipulationAttacker} from "../../src/oracle-manipulation/attacks/OracleManipulationAttacker.sol";

contract OracleManipulation01Test is Test {
    MockERC20 token;
    SimpleAMM amm;
    LendingPool lendingPool;

    MockPriceFeed priceFeed;
    LendingPoolFixed lendingPoolFixed;

    address attackerOwner = makeAddr("attackerOwner");

    // precio real: 100 ether / 1_000_000 TOKEN = 1e14 wei/TOKEN (0.0001 ETH/TOKEN)
    uint256 constant REAL_PRICE = 1e14;

    function setUp() public {
        token = new MockERC20("TOKEN", "TOK");

        amm = new SimpleAMM(address(token));
        lendingPool = new LendingPool(address(amm), address(token));

        // liquidez inicial del AMM: 100 ETH / 1.000.000 TOKEN
        token.mint(address(this), 1_000_000 ether);
        token.approve(address(amm), 1_000_000 ether);
        vm.deal(address(this), 100 ether);
        amm.addLiquidity{value: 100 ether}(1_000_000 ether);

        // liquidez de LendingPool para poder prestar
        vm.deal(address(lendingPool), 10 ether);

        // version con oraculo externo, ya con el precio real fijado
        priceFeed = new MockPriceFeed(int256(REAL_PRICE));
        lendingPoolFixed = new LendingPoolFixed(address(priceFeed), address(token));
        vm.deal(address(lendingPoolFixed), 10 ether);
    }

    /// @dev Traza exacta: el atacante mete 100 ETH en el AMM (100->200 ETH,
    ///      1.000.000->500.000 TOKEN), el precio pasa de 1e14 a 4e14 (4x).
    ///      Con 5.000 TOKEN de colateral, maxBorrow pasa de 0.35 ETH (real) a
    ///      1.4 ETH (manipulado) -- pedir 1 ETH prestado cabe manipulado pero
    ///      NO al precio real. Deshacer el swap devuelve exactamente los 100
    ///      ETH (AMM sin comisión, ida y vuelta sin perdidas): beneficio neto
    ///      exacto = 1 ETH, el importe prestado.
    function test_exploit_spotPriceManipulation() public {
        vm.startPrank(attackerOwner);
        OracleManipulationAttacker attacker =
            new OracleManipulationAttacker(address(amm), address(lendingPool), address(token));
        vm.stopPrank();

        // el atacante ya tiene colateral depositado antes de atacar
        token.mint(address(attacker), 5000 ether);
        vm.startPrank(address(attacker));
        token.approve(address(lendingPool), 5000 ether);
        lendingPool.depositCollateral(5000 ether);
        vm.stopPrank();

        vm.deal(attackerOwner, 100 ether);
        vm.prank(attackerOwner);
        attacker.attack{value: 100 ether}(1 ether);

        assertEq(attackerOwner.balance, 1 ether, "beneficio neto exacto: el ETH prestado");
        assertEq(amm.reserveETH(), 100 ether, "el AMM vuelve exactamente a su estado inicial");
        assertEq(amm.reserveToken(), 1_000_000 ether);
    }

    /// @dev Mismo intento (100 ETH de swap, pedir 1 ETH) pero el precio de
    ///      LendingPoolFixed no depende del AMM -- sigue siendo 1e14. Con
    ///      5.000 TOKEN de colateral, maxBorrow real es 0.35 ETH: pedir 1
    ///      ETH prestado excede el LTV y revierte.
    function test_mitigation_blocksSpotPriceManipulation() public {
        vm.startPrank(attackerOwner);
        OracleManipulationAttacker attacker =
            new OracleManipulationAttacker(address(amm), address(lendingPoolFixed), address(token));
        vm.stopPrank();

        token.mint(address(attacker), 5000 ether);
        vm.startPrank(address(attacker));
        token.approve(address(lendingPoolFixed), 5000 ether);
        lendingPoolFixed.depositCollateral(5000 ether);
        vm.stopPrank();

        vm.deal(attackerOwner, 100 ether);
        vm.prank(attackerOwner);
        vm.expectRevert(bytes("Exceeds LTV"));
        attacker.attack{value: 100 ether}(1 ether);
    }
}
