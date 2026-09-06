// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Recompensa por resolver un puzzle: la primera respuesta correcta
///         que llega a la mempool se lleva el premio.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 01 de Front-running & MEV
///      (SWC-114). `answer` viaja en texto claro dentro del calldata en
///      cuanto se transmite — visible en la mempool antes de confirmarse.
contract PuzzleBounty {
    bytes32 public immutable puzzleHash; // keccak256(respuesta correcta)
    bool public solved;

    constructor(bytes32 _puzzleHash) payable {
        puzzleHash = _puzzleHash;
    }

    function solve(uint256 answer) external {
        require(!solved, "Already solved");
        require(keccak256(abi.encodePacked(answer)) == puzzleHash, "Wrong answer");
        solved = true;
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
