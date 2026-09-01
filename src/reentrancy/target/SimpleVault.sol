// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Vault de ETH con retirada vulnerable a reentrancy de función única (SWC-107).
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 01 de la categoría Reentrancy.
///      El estado (`balances`) se actualiza DESPUÉS de la interacción externa.
///      Retira siempre el balance COMPLETO (no un importe parcial parametrizado):
///      el "effect" es una asignación a 0, no una resta, para que la reentrancy
///      recursiva no choque contra la proteccion de underflow de Solidity ^0.8.
contract SimpleVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /// @dev Orden vulnerable: interaction (call) antes de effect (balances = 0).
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
