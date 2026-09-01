// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice TODO: copia exacta de la versión vulnerable (InternalLedgerVault.sol).
///         Aplica la mitigación tú mismo.
contract InternalLedgerVaultFixed is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // TODO: mismo bug que la versión vulnerable -- aplica CEI y nonReentrant.
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        balances[msg.sender] = 0;
    }

    // TODO: esta función no hace ninguna llamada externa por sí misma,
    // pero comparte `balances` con withdraw() -- piensa si protegerla
    // solo a ella con nonReentrant, sin arreglar withdraw(), bastaría.
    function transferInternal(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
