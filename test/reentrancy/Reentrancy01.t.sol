// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {SimpleVault} from "../../src/reentrancy/SimpleVault.sol";
import {SimpleVaultFixed} from "../../src/reentrancy/SimpleVaultFixed.sol";
import {SimpleVaultAttacker} from "../../src/reentrancy/attacks/SimpleVaultAttacker.sol";

contract Reentrancy01Test is Test {
    SimpleVault vault;
    SimpleVaultFixed vaultFixed;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address attackerOwner = makeAddr("attackerOwner");

    function setUp() public {
        vault = new SimpleVault();
        vaultFixed = new SimpleVaultFixed();

        // dos depositantes legitimos, ajenos al ataque, en cada version del contrato
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

    /// @dev Traza esperada: vault arranca con 10 ether (alice+bob). El atacante deposita
    ///      1 ether (vault -> 11 ether) y reentra en withdraw() mientras balances[attacker]
    ///      sigue en 1 ether. Cada iteracion drena 1 ether real hasta que el balance del
    ///      vault cae por debajo de 1 ether: 11 retiradas de 1 ether = 11 ether extraidos.
    function test_exploit_drainsVault() public {
        assertEq(address(vault).balance, 10 ether);

        vm.deal(attackerOwner, 1 ether);
        vm.startPrank(attackerOwner);
        SimpleVaultAttacker attacker = new SimpleVaultAttacker(address(vault));
        attacker.attack{value: 1 ether}();
        attacker.collect();
        vm.stopPrank();

        assertEq(address(vault).balance, 0, "el vault debe quedar completamente drenado");
        assertEq(attackerOwner.balance, 11 ether, "1 ether propio + 10 ether ajenos");
    }

    /// @dev Con CEI (balances -= antes del call) y nonReentrant, la reentrada en
    ///      withdraw() revierte y arrastra toda la transaccion del atacante.
    function test_mitigation_blocksReentrancy() public {
        assertEq(address(vaultFixed).balance, 10 ether);

        vm.deal(attackerOwner, 1 ether);
        vm.startPrank(attackerOwner);
        SimpleVaultAttacker attacker = new SimpleVaultAttacker(address(vaultFixed));

        vm.expectRevert();
        attacker.attack{value: 1 ether}();
        vm.stopPrank();

        assertEq(address(vaultFixed).balance, 10 ether, "el vault corregido no pierde fondos");
        assertEq(attackerOwner.balance, 1 ether, "el ether del atacante vuelve al revertir toda la tx");
    }
}
