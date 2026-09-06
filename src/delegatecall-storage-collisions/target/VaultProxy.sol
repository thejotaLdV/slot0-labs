// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Proxy actualizable, correctamente implementado con el patrón
///         EIP-1967 -- este contrato NO tiene ningún bug. El problema del
///         Laboratorio 02 no está en el proxy, está en cómo cambia el layout
///         de storage entre versiones de la lógica.
contract VaultProxy {
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bb;

    constructor(address _implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly { sstore(slot, _implementation) }
    }

    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly { impl := sload(slot) }
    }

    // en produccion, protegido por onlyAdmin -- omitido para centrar el lab en el layout, no en control de acceso
    function upgradeTo(address newImpl) external {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly { sstore(slot, newImpl) }
    }

    fallback() external payable {
        address impl = implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
