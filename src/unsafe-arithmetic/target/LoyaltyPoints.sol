// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Sistema de puntos de fidelidad canjeables por ETH.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 02 de Aritmética insegura
///      (SWC-101 variante). Comprueba que el usuario tenga ALGÚN punto, no
///      que tenga los CLAIM_COST necesarios -- y la resta está en unchecked,
///      así que ese fallo de lógica ya no revierte por sí solo: desborda.
contract LoyaltyPoints {
    mapping(address => uint256) public points;
    uint256 public constant CLAIM_COST = 100;

    function earn(uint256 amount) external payable {
        points[msg.sender] += amount;
    }

    function claimReward(address payable to) external {
        require(points[msg.sender] > 0, "No points");

        unchecked {
            points[msg.sender] -= CLAIM_COST;
        }

        (bool success, ) = to.call{value: 0.01 ether}("");
        require(success, "Transfer failed");
    }

    function fund() external payable {}
}
