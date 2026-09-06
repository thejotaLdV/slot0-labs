// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {PuzzleBounty} from "../../src/front-running-mev/target/PuzzleBounty.sol";
import {PuzzleBountyFixed} from "../../src/front-running-mev/mitigations/PuzzleBountyFixed.sol";

contract FrontRunningMev01Test is Test {
    PuzzleBounty bounty;
    PuzzleBountyFixed bountyFixed;

    address attacker = makeAddr("attacker");
    address victim = makeAddr("victim");

    uint256 constant ANSWER = 42;

    function setUp() public {
        bytes32 puzzleHash = keccak256(abi.encodePacked(ANSWER));
        bounty = new PuzzleBounty{value: 2 ether}(puzzleHash);
        bountyFixed = new PuzzleBountyFixed{value: 2 ether}(puzzleHash);
    }

    /// @dev `answer` representa lo que el atacante leyó del calldata de la
    ///      transacción pendiente de victim en la mempool. El atacante actúa
    ///      PRIMERO con la respuesta ajena; la tx original de victim,
    ///      construida antes pero confirmada después, revierte.
    function test_exploit_mempoolFrontRunning() public {
        assertEq(keccak256(abi.encodePacked(ANSWER)), bounty.puzzleHash());

        vm.prank(attacker);
        bounty.solve(ANSWER);

        assertTrue(bounty.solved());
        assertEq(attacker.balance, 2 ether);

        vm.prank(victim);
        vm.expectRevert(bytes("Already solved"));
        bounty.solve(ANSWER);
    }

    /// @dev victim comete hash(answer, salt) y espera REVEAL_DELAY bloques.
    ///      El atacante ve answer+salt en el calldata de la tx de reveal de
    ///      victim, pendiente en la mempool, y copia exactamente esos mismos
    ///      valores -- pero nunca comprometió ese hash él mismo, así que
    ///      commitments[attacker] no coincide: su intento revierte. La
    ///      revelación legítima de victim, justo después, funciona con normalidad.
    function test_mitigation_blocksMempoolFrontRunning() public {
        bytes32 salt = keccak256("mi-salt-secreto");
        bytes32 hashedGuess = keccak256(abi.encodePacked(ANSWER, salt));

        vm.prank(victim);
        bountyFixed.commit(hashedGuess);

        vm.roll(block.number + bountyFixed.REVEAL_DELAY());

        vm.prank(attacker);
        vm.expectRevert(bytes("Bad reveal"));
        bountyFixed.reveal(ANSWER, salt);

        vm.prank(victim);
        bountyFixed.reveal(ANSWER, salt);

        assertTrue(bountyFixed.solved());
        assertEq(victim.balance, 2 ether);
        assertEq(attacker.balance, 0);
    }
}
