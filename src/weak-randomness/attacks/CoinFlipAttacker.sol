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

    // TODO: calcula el mismo `outcome` que calculará CoinFlip.play() --
    // exactamente la misma fórmula, con block.timestamp y block.prevrandao
    // -- y pásalo como guess. Al ejecutarse en la misma transacción, ambos
    // cálculos ven el mismo bloque: el resultado siempre coincide.
    function attack() external payable {
        // completa aquí
    }

    receive() external payable {}

    function collect() external {
        payable(owner).transfer(address(this).balance);
    }
}
