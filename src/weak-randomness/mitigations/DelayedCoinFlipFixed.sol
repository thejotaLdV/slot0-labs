// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: copia exacta de la versión vulnerable (DelayedCoinFlip.sol).
///         Aplica la mitigación tú mismo.
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

    // TODO: añade un límite superior -- require(block.number <=
    // bet.targetBlock + 256, "Window expired") -- para que nunca se llegue
    // a leer un blockhash ya caducado (bytes32(0), predecible).
    function resolve() external {
        Bet storage bet = bets[msg.sender];
        require(bet.targetBlock != 0, "No pending bet");
        require(block.number > bet.targetBlock, "Too soon");
        require(!bet.resolved, "Already resolved");

        bytes32 hash = blockhash(bet.targetBlock);
        bool outcome = uint256(hash) % 2 == 0;
        bet.resolved = true;

        if (bet.guess == outcome) {
            (bool success, ) = msg.sender.call{value: 2 ether}("");
            require(success, "Transfer failed");
        }
    }

    // TODO: si nadie llamó a resolve() antes de que expirara la ventana de
    // 256 bloques, el ETH apostado no debería quedar atrapado -- añade una
    // función que permita recuperar el 1 ether original una vez expirada
    // esa ventana (block.number > bet.targetBlock + 256 && !bet.resolved).
    function claimRefund() external {
        // completa aquí
    }

    function fund() external payable {}
}
