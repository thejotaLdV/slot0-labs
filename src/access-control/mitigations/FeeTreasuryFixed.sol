// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: copia exacta de la versión vulnerable (FeeTreasury.sol).
///         Aplica la mitigación tú mismo.
contract FeeTreasuryFixed {
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

    // TODO: a esta función le falta exactamente lo mismo que a
    // collectFees() le sobra por encima -- compáralas.
    function withdrawAll(address payable to) external {
        uint256 balance = address(this).balance;
        (bool success, ) = to.call{value: balance}("");
        require(success, "Transfer failed");
    }
}
