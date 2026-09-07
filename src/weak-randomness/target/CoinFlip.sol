// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Cara o cruz con recompensa doble si aciertas.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 01 de Aleatoriedad débil
///      (SWC-120). `outcome` se deriva de valores que cualquier contrato
///      puede leer y calcular en el mismo instante, antes de apostar.
contract CoinFlip {
    mapping(address => uint256) public wins;

    function play(bool guess) external payable {
        require(msg.value == 1 ether, "Bet 1 ether");

        bool outcome = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
        ) % 2 == 0;

        if (guess == outcome) {
            wins[msg.sender]++;
            (bool success, ) = msg.sender.call{value: 2 ether}("");
            require(success, "Transfer failed");
        }
    }

    function fund() external payable {}
}
