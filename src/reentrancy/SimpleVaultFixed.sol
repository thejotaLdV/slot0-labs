// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice TODO: este contrato es, de momento, una copia exacta de la
///         versión vulnerable (SimpleVault.sol) con ReentrancyGuard ya
///         importado pero SIN USAR. Tu tarea es aplicar la mitigación real.
contract SimpleVaultFixed is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // TODO: esta función tiene el mismo bug que la versión vulnerable.
    //
    // Pista 1: aplica el patrón Checks-Effects-Interactions -- ¿en qué
    // orden deberían ir la llamada externa (`call`) y la línea que pone
    // `balances[msg.sender]` a 0?
    //
    // Pista 2: añade el modifier `nonReentrant` a esta función como
    // segunda barrera, independiente del orden del código.
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        balances[msg.sender] = 0;
    }

    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
