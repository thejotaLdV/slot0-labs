// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Registro de administradores usado por otros contratos como fuente
///         de verdad para decisiones de permisos.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 04 de Control de acceso (SWC-106).
contract AccessManager {
    mapping(address => bool) public isAdmin;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not admin");
        _;
    }

    constructor() {
        isAdmin[msg.sender] = true;
    }

    // vulnerable: sin proteccion propia -- cualquiera puede autoconcederse el rol
    function grantAdmin(address account) external {
        isAdmin[account] = true;
    }

    function revokeAdmin(address account) external onlyAdmin {
        isAdmin[account] = false;
    }
}
