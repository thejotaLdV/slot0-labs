// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockGovToken} from "../mocks/MockGovToken.sol";
import {FlashLender} from "../../src/flash-loan-attacks/target/FlashLender.sol";
import {Governor} from "../../src/flash-loan-attacks/target/Governor.sol";
import {Treasury} from "../../src/flash-loan-attacks/target/Treasury.sol";
import {GovernorFixed} from "../../src/flash-loan-attacks/mitigations/GovernorFixed.sol";
import {GovernanceFlashAttacker} from "../../src/flash-loan-attacks/attacks/GovernanceFlashAttacker.sol";

contract FlashLoanAttacks02Test is Test {
    MockGovToken govToken;
    FlashLender lender;

    Governor governor;
    Treasury treasury;

    GovernorFixed governorFixed;
    Treasury treasuryFixed;

    address attackerOwner = makeAddr("attackerOwner");

    function setUp() public {
        govToken = new MockGovToken();
        lender = new FlashLender(address(govToken));

        // liquidez del flash lender: 600.000 GOV disponibles para prestar
        govToken.mint(address(lender), 600_000 ether);

        // Governor y Treasury se referencian mutuamente, ambos como
        // immutable -- se predice la direccion de Treasury (el siguiente
        // contrato que desplegara este mismo test) antes de crear Governor
        address predictedTreasury = vm.computeCreateAddress(address(this), vm.getNonce(address(this)) + 1);
        governor = new Governor(address(govToken), predictedTreasury);
        treasury = new Treasury(address(governor));
        assertEq(address(treasury), predictedTreasury, "prediccion de direccion incorrecta");
        vm.deal(address(treasury), 50 ether);

        address predictedTreasuryFixed = vm.computeCreateAddress(address(this), vm.getNonce(address(this)) + 1);
        governorFixed = new GovernorFixed(address(govToken), predictedTreasuryFixed);
        treasuryFixed = new Treasury(address(governorFixed));
        assertEq(address(treasuryFixed), predictedTreasuryFixed, "prediccion de direccion incorrecta");
        vm.deal(address(treasuryFixed), 50 ether);
    }

    /// @dev Traza exacta: flashAmount=600.000 GOV >= QUORUM (500.000 GOV).
    ///      propose+vote+execute suceden en la misma transaccion que el
    ///      flash loan -- sin snapshot ni timelock, el poder de voto
    ///      prestado cuenta igual que si fuera propio. La tesoreria
    ///      (50 ETH) se transfiere entera a attackerOwner.
    function test_exploit_flashGovernance() public {
        vm.startPrank(attackerOwner);
        GovernanceFlashAttacker attacker =
            new GovernanceFlashAttacker(address(governor), address(treasury), address(lender), address(govToken));
        vm.stopPrank();

        vm.prank(attackerOwner);
        attacker.attack(600_000 ether);

        assertEq(attackerOwner.balance, 50 ether, "toda la tesoreria transferida al atacante");
        assertEq(address(treasury).balance, 0);
        assertEq(govToken.balanceOf(address(lender)), 600_000 ether, "el prestamista recupera su liquidez");
    }

    /// @dev Mismo intento contra GovernorFixed: snapshotBlock = block.number - 1,
    ///      fijado en propose(). El flash loan y la propuesta ocurren en el
    ///      mismo block.number -- getPastVotes(attacker, block.number - 1)
    ///      devuelve 0 (el checkpoint del atacante es de "ahora", no de antes).
    ///      votesFor se queda en 0, muy por debajo del quorum: execute() revierte.
    function test_mitigation_blocksFlashGovernance() public {
        vm.startPrank(attackerOwner);
        GovernanceFlashAttacker attackerFixed = new GovernanceFlashAttacker(
            address(governorFixed), address(treasuryFixed), address(lender), address(govToken)
        );
        vm.stopPrank();

        vm.prank(attackerOwner);
        vm.expectRevert(bytes("Quorum not reached"));
        attackerFixed.attack(600_000 ether);

        assertEq(address(treasuryFixed).balance, 50 ether, "la tesoreria permanece intacta");
    }
}
