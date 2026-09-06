// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Contrato de lógica pensado para usarse detrás de Proxy.sol vía
///         delegatecall. No tiene ningún bug propio -- el problema es que su
///         layout de storage coincide, slot a slot, con el de Proxy.
contract Logic {
    address public owner;  // slot 0 — para Logic, "owner"; para Proxy, es "implementation"
    uint256 public value;  // slot 1 — para Logic, "value"; para Proxy, es "admin"

    function setOwner(address _owner) external {
        owner = _owner;
    }

    function setValue(uint256 _value) external {
        value = _value;
    }
}
