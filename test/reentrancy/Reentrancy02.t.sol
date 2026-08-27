// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {InternalLedgerVault} from "../../src/reentrancy/InternalLedgerVault.sol";
import {InternalLedgerVaultFixed} from "../../src/reentrancy/InternalLedgerVaultFixed.sol";
import {CrossFunctionAttacker} from "../../src/reentrancy/attacks/CrossFunctionAttacker.sol";

contract Reentrancy02Test is Test {
    InternalLedgerVault vault;
    InternalLedgerVaultFixed vaultFixed;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address accomplice = makeAddr("accomplice");
    address attackerOwner = makeAddr("attackerOwner");

    function setUp() public {
        vault = new InternalLedgerVault();
        vaultFixed = new InternalLedgerVaultFixed();

        vm.deal(alice, 5 ether);
        vm.prank(alice);
        vault.deposit{value: 5 ether}();
        vm.deal(bob, 5 ether);
        vm.prank(bob);
        vault.deposit{value: 5 ether}();

        vm.deal(alice, 5 ether);
        vm.prank(alice);
        vaultFixed.deposit{value: 5 ether}();
        vm.deal(bob, 5 ether);
        vm.prank(bob);
        vaultFixed.deposit{value: 5 ether}();
    }

    /// @dev Traza esperada (N = 3 ether): vault arranca en 13 ether (10 legitimos + 3
    ///      del atacante). Durante el callback de withdraw(), balances[attacker] sigue
    ///      en 3 ether (aun sin poner a cero) y se mueve a `accomplice` via
    ///      transferInternal(). El atacante se queda con 3 ether reales (del call),
    ///      dejando el vault en 13 - 3 = 10 ether. `accomplice` retira despues otros
    ///      3 ether de mas: vault en 10 - 3 = 7 ether. Total extraido: 6 ether por
    ///      solo 3 depositados.
    function test_exploit_crossFunctionReentrancy() public {
        assertEq(address(vault).balance, 10 ether);

        vm.deal(attackerOwner, 3 ether);
        vm.startPrank(attackerOwner);
        CrossFunctionAttacker attacker = new CrossFunctionAttacker(address(vault), accomplice);
        attacker.attack{value: 3 ether}();
        vm.stopPrank();

        assertEq(address(attacker).balance, 3 ether, "el atacante recibe su deposito via el callback");
        assertEq(vault.balances(accomplice), 3 ether, "el complice recibe el mismo balance, duplicado");
        assertEq(vault.balances(address(attacker)), 0);
        assertEq(address(vault).balance, 10 ether, "13 - 3: solo el atacante ha retirado hasta ahora");

        vm.prank(accomplice);
        vault.withdraw();

        assertEq(accomplice.balance, 3 ether, "el complice retira el balance duplicado");
        assertEq(address(vault).balance, 7 ether, "10 - 3: 6 ether extraidos en total por 3 depositados");
    }

    /// @dev Con balances[attacker] puesto a 0 ANTES del call (CEI), el callback
    ///      observa un balance ya vacio y `transferInternal` nunca llega a moverse:
    ///      el ataque no revierte, pero tampoco logra nada — el atacante solo
    ///      recupera exactamente lo que deposito.
    function test_mitigation_blocksCrossFunctionReentrancy() public {
        assertEq(address(vaultFixed).balance, 10 ether);

        vm.deal(attackerOwner, 3 ether);
        vm.startPrank(attackerOwner);
        CrossFunctionAttacker attacker = new CrossFunctionAttacker(address(vaultFixed), accomplice);
        attacker.attack{value: 3 ether}(); // no revierte: withdraw() legitimo
        vm.stopPrank();

        assertEq(vaultFixed.balances(accomplice), 0, "el complice no consigue nada");
        assertEq(address(attacker).balance, 3 ether, "el atacante solo recupera lo suyo");
        assertEq(address(vaultFixed).balance, 10 ether, "el resto del vault permanece intacto");
    }
}
