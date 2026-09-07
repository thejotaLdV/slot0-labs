// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DelayedCoinFlipFixed {
    struct Bet {
        bool guess;
        uint256 targetBlock;
        bool resolved;
    }
    mapping(address => Bet) public bets;

    function placeBet(bool guess) external payable {
        require(msg.value == 1 ether, "Bet 1 ether");
        require(bets[msg.sender].targetBlock == 0, "Bet already pending");
        bets[msg.sender] = Bet({guess: guess, targetBlock: block.number + 5, resolved: false});
    }

    function resolve() external {
        Bet storage bet = bets[msg.sender];
        require(bet.targetBlock != 0, "No pending bet");
        require(block.number > bet.targetBlock, "Too soon");
        require(block.number <= bet.targetBlock + 256, "Window expired");
        require(!bet.resolved, "Already resolved");

        bytes32 hash = blockhash(bet.targetBlock);
        bool outcome = uint256(hash) % 2 == 0;
        bet.resolved = true;

        if (bet.guess == outcome) {
            (bool success, ) = msg.sender.call{value: 2 ether}("");
            require(success, "Transfer failed");
        }
    }

    function claimRefund() external {
        Bet storage bet = bets[msg.sender];
        require(bet.targetBlock != 0, "No pending bet");
        require(!bet.resolved, "Already resolved");
        require(block.number > bet.targetBlock + 256, "Window still open");

        bet.resolved = true;
        (bool success, ) = msg.sender.call{value: 1 ether}("");
        require(success, "Transfer failed");
    }

    function fund() external payable {}
}
