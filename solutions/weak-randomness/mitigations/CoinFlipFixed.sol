// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CoinFlipFixed {
    struct Bet {
        bool guess;
        uint256 targetBlock;
        bool resolved;
    }
    mapping(address => Bet) public bets;
    mapping(address => uint256) public wins;

    function play(bool guess) external payable {
        require(msg.value == 1 ether, "Bet 1 ether");
        require(bets[msg.sender].targetBlock == 0, "Bet already pending");
        bets[msg.sender] = Bet({guess: guess, targetBlock: block.number + 1, resolved: false});
    }

    function resolve() external {
        Bet storage bet = bets[msg.sender];
        require(bet.targetBlock != 0, "No pending bet");
        require(block.number > bet.targetBlock, "Too soon");
        require(!bet.resolved, "Already resolved");
        bet.resolved = true;

        bool outcome = uint256(blockhash(bet.targetBlock)) % 2 == 0;
        if (bet.guess == outcome) {
            wins[msg.sender]++;
            (bool success, ) = msg.sender.call{value: 2 ether}("");
            require(success, "Transfer failed");
        }
    }

    function fund() external payable {}
}
