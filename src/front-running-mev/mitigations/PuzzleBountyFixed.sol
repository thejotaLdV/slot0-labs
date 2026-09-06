// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: copia exacta de la versión vulnerable (PuzzleBounty.sol).
///         Aplica la mitigación tú mismo con un esquema commit-reveal.
contract PuzzleBountyFixed {
    bytes32 public immutable puzzleHash;
    mapping(address => bytes32) public commitments;
    mapping(address => uint256) public commitBlock;
    uint256 public constant REVEAL_DELAY = 5; // bloques minimos entre commit y reveal
    bool public solved;

    constructor(bytes32 _puzzleHash) payable {
        puzzleHash = _puzzleHash;
    }

    // TODO fase 1: guarda `hashedGuess` (= keccak256(answer, salt), calculado
    // fuera de la cadena) junto con block.number, indexado por msg.sender.
    // Nadie puede copiar la respuesta real de aquí -- solo ven un hash.
    function commit(bytes32 hashedGuess) external {
        // completa aquí
    }

    // TODO fase 2: exige que hayan pasado REVEAL_DELAY bloques desde el
    // commit de msg.sender, comprueba que keccak256(answer, salt) coincide
    // con lo comprometido, y solo entonces valida la respuesta real y paga.
    function reveal(uint256 answer, bytes32 salt) external {
        require(!solved, "Already solved");
        require(keccak256(abi.encodePacked(answer)) == puzzleHash, "Wrong answer");
        solved = true;
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
