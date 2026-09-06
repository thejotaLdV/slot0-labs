// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: copia exacta de la versión vulnerable (Proxy.sol), sin la
///         variable `implementation` en slot 0. Aplica la mitigación tú mismo.
contract ProxyFixed {
    // TODO: declara aquí una constante bytes32 con el slot EIP-1967 para el
    // puntero de implementación:
    // keccak256("eip1967.proxy.implementation") - 1
    // = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bb

    constructor(address _implementation) {
        // TODO: en vez de "implementation = _implementation;", guarda la
        // dirección con `sstore` en el slot EIP-1967 (fuera del rango 0..N
        // que cualquier Logic normal pudiera pisar).
    }

    // TODO: sustituye la variable pública `implementation` por esta función,
    // que lee la dirección con `sload` desde el slot EIP-1967.
    function implementation() public view returns (address impl) {}

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
