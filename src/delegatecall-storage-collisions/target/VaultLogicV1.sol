// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VaultLogicV1 {
    uint256 public totalDeposits;                  // slot 0
    mapping(address => uint256) public balances;   // slot 1

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
