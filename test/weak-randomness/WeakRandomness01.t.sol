// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CoinFlip} from "../../src/weak-randomness/target/CoinFlip.sol";
import {CoinFlipFixed} from "../../src/weak-randomness/mitigations/CoinFlipFixed.sol";
import {CoinFlipAttacker} from "../../src/weak-randomness/attacks/CoinFlipAttacker.sol";

contract WeakRandomness01Test is Test {
    CoinFlip coinFlip;
    CoinFlipFixed coinFlipFixed;

    address attackerOwner = makeAddr("attackerOwner");

    function setUp() public {
        coinFlip = new CoinFlip();
        vm.deal(address(this), 20 ether);
        coinFlip.fund{value: 20 ether}();

        coinFlipFixed = new CoinFlipFixed();
        coinFlipFixed.fund{value: 20 ether}();
    }

    /// @dev El atacante calcula `outcome` con la MISMA fórmula que
    ///      CoinFlip.play(), en la misma transacción -- ambos cálculos ven
    ///      el mismo block.timestamp y block.prevrandao, así que siempre
    ///      coinciden. 10 apuestas en 10 bloques distintos, 10 de 10 aciertos.
    function test_exploit_predictableCoinFlip() public {
        vm.startPrank(attackerOwner);
        CoinFlipAttacker attacker = new CoinFlipAttacker(address(coinFlip));
        vm.stopPrank();

        vm.deal(address(attacker), 10 ether);

        for (uint256 i = 0; i < 10; i++) {
            attacker.attack{value: 1 ether}();
            vm.roll(block.number + 1);
            vm.warp(block.timestamp + 12);
        }

        vm.prank(attackerOwner);
        attacker.collect();

        assertEq(coinFlip.wins(address(attacker)), 10, "10 de 10 -- no es azar");
        assertEq(attackerOwner.balance, 10 ether, "beneficio neto: 10 apuestas ganadas de 1 ether cada una");
    }

    /// @dev Mismo intento contra CoinFlipFixed: play() ya no resuelve nada,
    ///      solo registra la apuesta con un targetBlock FUTURO. Intentar
    ///      resolver en el mismo bloque en el que se apostó -- el ataque
    ///      original, adaptado a esta interfaz -- revierte "Too soon".
    function test_mitigation_blocksPredictableCoinFlip() public {
        address attacker = makeAddr("attacker");
        vm.deal(attacker, 1 ether);

        vm.startPrank(attacker);
        coinFlipFixed.play{value: 1 ether}(true);

        vm.expectRevert(bytes("Too soon"));
        coinFlipFixed.resolve();
        vm.stopPrank();
    }
}
