// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Tesorería de comisiones con una función de retirada sin proteger.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 01 de Control de acceso (SWC-105).
contract FeeTreasury {
    address public owner;
    mapping(address => uint256) public deposits;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function collectFees(uint256 amount, address payable to) external onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // vulnerable: le falta el modifier onlyOwner
    function withdrawAll(address payable to) external {
        uint256 balance = address(this).balance;
        (bool success, ) = to.call{value: balance}("");
        require(success, "Transfer failed");
    }
}
