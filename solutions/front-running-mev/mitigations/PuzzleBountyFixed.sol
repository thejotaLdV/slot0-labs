// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PuzzleBountyFixed {
    bytes32 public immutable puzzleHash;
    mapping(address => bytes32) public commitments;
    mapping(address => uint256) public commitBlock;
    uint256 public constant REVEAL_DELAY = 5;
    bool public solved;

    constructor(bytes32 _puzzleHash) payable {
        puzzleHash = _puzzleHash;
    }

    function commit(bytes32 hashedGuess) external {
        commitments[msg.sender] = hashedGuess;
        commitBlock[msg.sender] = block.number;
    }

    function reveal(uint256 answer, bytes32 salt) external {
        require(!solved, "Already solved");
        require(block.number >= commitBlock[msg.sender] + REVEAL_DELAY, "Too soon");
        require(keccak256(abi.encodePacked(answer, salt)) == commitments[msg.sender], "Bad reveal");
        require(keccak256(abi.encodePacked(answer)) == puzzleHash, "Wrong answer");
        solved = true;
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
