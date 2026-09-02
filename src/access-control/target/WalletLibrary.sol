// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Inspirado en el hackeo de Parity Multisig (2017): un inicializador
///         que se puede llamar en cualquier momento, por cualquiera.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 03 de Control de acceso (SWC-118).
contract WalletLibrary {
    address public owner;
    mapping(address => uint256) public balances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // vulnerable: se puede llamar en cualquier momento, por cualquiera,
    // tantas veces como se quiera -- no hay flag de "ya inicializado"
    function initWallet(address _owner) external {
        owner = _owner;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function kill(address payable to) external onlyOwner {
        selfdestruct(to);
    }
}
