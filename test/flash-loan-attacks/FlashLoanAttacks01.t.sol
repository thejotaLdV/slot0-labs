// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {FlashLender} from "../../src/flash-loan-attacks/target/FlashLender.sol";
import {RewardStaking} from "../../src/flash-loan-attacks/target/RewardStaking.sol";
import {RewardStakingFixed} from "../../src/flash-loan-attacks/mitigations/RewardStakingFixed.sol";
import {StakingFlashAttacker} from "../../src/flash-loan-attacks/attacks/StakingFlashAttacker.sol";

contract FlashLoanAttacks01Test is Test {
    MockERC20 stakeToken;
    FlashLender lender;
    RewardStaking staking;
    RewardStakingFixed stakingFixed;

    address legitStaker = makeAddr("legitStaker");
    address attackerOwner = makeAddr("attackerOwner");

    function setUp() public {
        stakeToken = new MockERC20("STAKE", "STK");
        lender = new FlashLender(address(stakeToken));

        staking = new RewardStaking(address(stakeToken));
        stakingFixed = new RewardStakingFixed(address(stakeToken));

        // liquidez del flash lender: 90.000 TOKEN disponibles para prestar
        stakeToken.mint(address(lender), 90_000 ether);

        // un staker legitimo, ya con 100.000 TOKEN en juego desde antes
        // (en cada version -- 200.000 en total)
        stakeToken.mint(legitStaker, 200_000 ether);
        vm.startPrank(legitStaker);
        stakeToken.approve(address(staking), 100_000 ether);
        staking.stake(100_000 ether);
        stakeToken.approve(address(stakingFixed), 100_000 ether);
        stakingFixed.stake(100_000 ether);
        vm.stopPrank();

        // pool de recompensas: 10 ETH en cada version
        vm.deal(address(this), 20 ether);
        staking.addRewards{value: 10 ether}();
        stakingFixed.addRewards{value: 10 ether}();
    }

    /// @dev Traza exacta: flashAmount=90.000 TOKEN. totalStaked pasa de
    ///      100.000 a 190.000. share = 10 ether * 90.000/190.000 =
    ///      4.736842105263157894 ether exactos -- reclamado con 0 tiempo
    ///      real de permanencia, en la misma transaccion del flash loan.
    function test_exploit_flashStakingReward() public {
        vm.startPrank(attackerOwner);
        StakingFlashAttacker attacker =
            new StakingFlashAttacker(address(staking), address(lender), address(stakeToken));
        vm.stopPrank();

        vm.prank(attackerOwner);
        attacker.attack(90_000 ether);

        assertEq(attackerOwner.balance, 4736842105263157894, "share exacto reclamado sin permanencia real");
        assertEq(staking.totalStaked(), 100_000 ether, "el flash loan se devuelve integro, sin dejar rastro");
        assertEq(stakeToken.balanceOf(address(lender)), 90_000 ether, "el prestamista recupera su liquidez");
    }

    /// @dev Mismo intento contra RewardStakingFixed: stake() registra
    ///      block.timestamp, y claimReward() exige 1 dia transcurrido -- en
    ///      la misma transaccion (mismo timestamp), la resta da 0 < 1 days.
    function test_mitigation_blocksFlashStakingReward() public {
        vm.startPrank(attackerOwner);
        StakingFlashAttacker attackerFixed =
            new StakingFlashAttacker(address(stakingFixed), address(lender), address(stakeToken));
        vm.stopPrank();

        vm.prank(attackerOwner);
        vm.expectRevert(bytes("Too soon"));
        attackerFixed.attack(90_000 ether);
    }
}
