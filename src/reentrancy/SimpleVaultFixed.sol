// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Versión corregida de SimpleVault: patrón Checks-Effects-Interactions
///         más ReentrancyGuard como segunda barrera independiente del orden del código.
contract SimpleVaultFixed is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        balances[msg.sender] = 0; // effect antes de la interaccion

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
