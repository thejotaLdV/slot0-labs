// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @notice Token con un pragma anterior a Solidity 0.8.0 -- sin comprobación
///         automática de overflow/underflow en la aritmética.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 01 de Aritmética insegura
///      (SWC-101). `cnt * value` puede desbordar; el resultado envuelve
///      silenciosamente en vez de revertir.
contract LegacyToken {
    string public name = "LegacyToken";
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    constructor(uint256 initialSupply) {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }

    // vulnerable: `cnt * value` puede desbordar en Solidity <0.8.0 --
    // el resultado envuelve silenciosamente, sin revertir
    function batchTransfer(address[] memory receivers, uint256 value) public returns (bool) {
        uint256 cnt = receivers.length;
        uint256 amount = uint256(cnt) * value;
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        for (uint256 i = 0; i < cnt; i++) {
            balanceOf[receivers[i]] += value;
        }
        return true;
    }
}
