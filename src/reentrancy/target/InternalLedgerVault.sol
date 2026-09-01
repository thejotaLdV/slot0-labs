// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Vault con dos funciones que comparten el mapping `balances`.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 02 de la categoría Reentrancy.
///      `withdraw()` es vulnerable a reentrancy; `transferInternal()` no hace
///      ninguna llamada externa por sí misma, pero comparte el mismo estado.
contract InternalLedgerVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        balances[msg.sender] = 0;
    }

    function transferInternal(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
