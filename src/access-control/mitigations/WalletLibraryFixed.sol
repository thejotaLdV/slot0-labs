// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: copia exacta de la versión vulnerable (WalletLibrary.sol).
///         Aplica la mitigación tú mismo.
contract WalletLibraryFixed {
    address public owner;
    mapping(address => uint256) public balances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // TODO: falta impedir que esta función se pueda volver a llamar una vez
    // que el wallet ya tiene owner. Necesitas una variable de estado nueva
    // que recuerde si ya se inicializó, y comprobarla aquí.
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
