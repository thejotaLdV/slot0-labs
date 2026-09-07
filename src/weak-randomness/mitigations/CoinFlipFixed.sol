// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: misma idea que CoinFlip.sol, pero separando "apostar" de
///         "resolver" en dos pasos, para que la fuente de aleatoriedad no
///         exista todavía en el momento de apostar. Aplica la mitigación
///         tú mismo.
contract CoinFlipFixed {
    struct Bet {
        bool guess;
        uint256 targetBlock;
        bool resolved;
    }
    mapping(address => Bet) public bets;
    mapping(address => uint256) public wins;

    // TODO: en vez de resolver aquí mismo, guarda la apuesta (guess) junto
    // con un targetBlock FUTURO (por ejemplo, block.number + 1) -- un bloque
    // que todavía no existe, así que su blockhash es imposible de calcular
    // ahora, por nadie.
    function play(bool guess) external payable {
        require(msg.value == 1 ether, "Bet 1 ether");
        // completa aquí
    }

    // TODO: exige que ya haya pasado targetBlock (require block.number >
    // targetBlock, mensaje "Too soon"), que la apuesta exista y no este ya
    // resuelta, y calcula outcome con blockhash(targetBlock) -- un valor que
    // no existía cuando se llamó a play().
    function resolve() external {
        // completa aquí
    }

    function fund() external payable {}
}
