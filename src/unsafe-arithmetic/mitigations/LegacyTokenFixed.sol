// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Idéntico a LegacyToken.sol -- ni una línea de lógica cambia.
/// @dev La mitigación de este laboratorio no es un cambio de código: es un
///      cambio de COMPILADOR. Con pragma >=0.8.0, `cnt * value` revierte
///      automáticamente si desborda -- no hace falta SafeMath ni ningún
///      require adicional. Por eso este fichero no es un stub: no hay nada
///      que tú tengas que escribir aquí.
contract LegacyTokenFixed {
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

    function batchTransfer(address[] memory receivers, uint256 value) public returns (bool) {
        uint256 cnt = receivers.length;
        uint256 amount = uint256(cnt) * value; // revierte solo con overflow, gracias al pragma
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        for (uint256 i = 0; i < cnt; i++) {
            balanceOf[receivers[i]] += value;
        }
        return true;
    }
}
