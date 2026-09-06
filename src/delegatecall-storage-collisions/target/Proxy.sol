// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Proxy minimalista basado en delegatecall.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 01 de Delegatecall & Storage
///      Collisions (SWC-112). Guarda `implementation` en el slot 0, el mismo
///      slot que Logic.sol usa para su propia primera variable de estado.
contract Proxy {
    address public implementation; // slot 0
    address public admin;          // slot 1

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    fallback() external payable {
        address impl = implementation;
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
