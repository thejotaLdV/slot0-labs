// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: copia exacta de la versión vulnerable (AccessManager.sol).
///         Aplica la mitigación tú mismo. RewardsPool.sol no necesita ningún
///         cambio -- el bug está entero aquí, no en quien confía en este contrato.
contract AccessManagerFixed {
    mapping(address => bool) public isAdmin;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not admin");
        _;
    }

    constructor() {
        isAdmin[msg.sender] = true;
    }

    // TODO: compárala con revokeAdmin(), justo debajo -- le falta exactamente
    // lo mismo que a esa función le sobra.
    function grantAdmin(address account) external {
        isAdmin[account] = true;
    }

    function revokeAdmin(address account) external onlyAdmin {
        isAdmin[account] = false;
    }
}
