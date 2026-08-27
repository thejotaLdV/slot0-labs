// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {LiquidityPool} from "../../src/reentrancy/LiquidityPool.sol";
import {LiquidityPoolFixed} from "../../src/reentrancy/LiquidityPoolFixed.sol";
import {LoanManager} from "../../src/reentrancy/LoanManager.sol";
import {ReadOnlyReentrancyAttacker} from "../../src/reentrancy/attacks/ReadOnlyReentrancyAttacker.sol";

contract Reentrancy03Test is Test {
    LiquidityPool pool;
    LoanManager loanManager;
    ReadOnlyReentrancyAttacker attacker;

    address lp1 = makeAddr("lp1");
    address victim = makeAddr("victim");
    address attackerOwner = makeAddr("attackerOwner");

    // Fixture: lp1 aporta 50 ether, victim aporta 20 ether (shares 1:1 al ser
    // deposito inicial/proporcional). victim deposita sus 20 shares como
    // colateral y pide prestados 10 ether -> ratio real = 200% (sano, con
    // margen respecto al 150% de LIQUIDATION_THRESHOLD).
    function setUp() public {
        pool = new LiquidityPool();
        loanManager = new LoanManager(address(pool));

        vm.deal(lp1, 50 ether);
        vm.prank(lp1);
        pool.addLiquidity{value: 50 ether}();

        vm.deal(victim, 20 ether);
        vm.prank(victim);
        pool.addLiquidity{value: 20 ether}();

        vm.startPrank(victim);
        loanManager.depositCollateral(20 ether);
        loanManager.borrow(10 ether);
        vm.stopPrank();

        vm.startPrank(attackerOwner);
        attacker = new ReadOnlyReentrancyAttacker(address(pool), address(loanManager), victim);
        vm.stopPrank();
    }

    function test_victimPositionIsHealthyBeforeAttack() public {
        vm.expectRevert(bytes("Healthy position"));
        loanManager.liquidate(victim);
    }

    /// @dev Traza esperada: el atacante entra como LP con 130 ether (mucho mayor
    ///      que el resto del pool: 50+20=70 ether previos -> total 200 ether,
    ///      200 shares). Al retirar sus 130 shares, el pool envia 130 ether
    ///      ANTES de descontar totalShares. Durante ese instante:
    ///        precio = balance_real(70e18) * 1e18 / totalShares_sin_actualizar(200e18)
    ///               = 0.35e18   (35% del precio real, muy deprimido)
    ///      El colateral de victim (20 shares, realmente 20 ether) se valora en
    ///      apenas 7 ether -> ratio = 7/10 = 70% < 150% -> liquidable, aunque su
    ///      posicion real seguia al 200%.
    function test_exploit_readOnlyReentrancy() public {
        vm.deal(attackerOwner, 130 ether);
        vm.startPrank(attackerOwner);
        attacker.seedLiquidity{value: 130 ether}();
        attacker.attack(130 ether);
        vm.stopPrank();

        assertEq(loanManager.collateralShares(victim), 0, "el colateral de victim fue embargado");
        assertEq(loanManager.debt(victim), 0);
        assertEq(
            loanManager.collateralShares(address(attacker)),
            20 ether,
            "el atacante se queda con el colateral de victim"
        );

        // tras completar removeLiquidity, la contabilidad del pool vuelve a
        // estar sincronizada y el precio refleja de nuevo la realidad
        assertEq(pool.totalShares(), 70 ether);
        assertEq(address(pool).balance, 70 ether);
        assertEq(pool.getVirtualPrice(), 1e18);
    }

    /// @dev Con CEI, totalShares/reserveETH ya valen 70 ether cuando se ejecuta
    ///      la interaccion externa, asi que getVirtualPrice() durante el
    ///      callback ya devuelve 1e18 (normal) — liquidate(victim) revierte con
    ///      "Healthy position", y ese revert de bajo nivel hace fallar el
    ///      require(success) de removeLiquidity, arrastrando TODA la llamada
    ///      attack() (el mensaje que finalmente se propaga es "Transfer failed",
    ///      no "Healthy position", porque el revert cruza una llamada de bajo nivel).
    function test_mitigation_blocksReadOnlyReentrancy() public {
        LiquidityPoolFixed poolFixed = new LiquidityPoolFixed();
        LoanManager loanManagerFixed = new LoanManager(address(poolFixed));
        vm.startPrank(attackerOwner);
        ReadOnlyReentrancyAttacker attackerFixed =
            new ReadOnlyReentrancyAttacker(address(poolFixed), address(loanManagerFixed), victim);
        vm.stopPrank();

        vm.deal(lp1, 50 ether);
        vm.prank(lp1);
        poolFixed.addLiquidity{value: 50 ether}();

        vm.deal(victim, 20 ether);
        vm.prank(victim);
        poolFixed.addLiquidity{value: 20 ether}();

        vm.startPrank(victim);
        loanManagerFixed.depositCollateral(20 ether);
        loanManagerFixed.borrow(10 ether);
        vm.stopPrank();

        vm.deal(attackerOwner, 130 ether);
        vm.startPrank(attackerOwner);
        attackerFixed.seedLiquidity{value: 130 ether}();

        vm.expectRevert(bytes("Transfer failed"));
        attackerFixed.attack(130 ether);
        vm.stopPrank();

        assertEq(loanManagerFixed.collateralShares(victim), 20 ether, "el colateral de victim no se toca");
        assertEq(loanManagerFixed.debt(victim), 10 ether, "la deuda de victim no se toca");
    }
}
