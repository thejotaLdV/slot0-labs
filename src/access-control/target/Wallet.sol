// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Wallet simple que autentica con tx.origin en vez de msg.sender.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 02 de Control de acceso (SWC-115).
contract Wallet {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function deposit() external payable {}

    // vulnerable: usa tx.origin en vez de msg.sender
    function transfer(address payable to, uint256 amount) external {
        require(tx.origin == owner, "Not owner");
        to.transfer(amount);
    }

    receive() external payable {}
}
