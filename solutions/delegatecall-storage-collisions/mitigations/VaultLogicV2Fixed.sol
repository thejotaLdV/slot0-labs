// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VaultLogicV2Fixed {
    uint256 public totalDeposits;                   // slot 0 — SIN TOCAR, igual que V1
    mapping(address => uint256) public balances;    // slot 1 — SIN TOCAR, igual que V1
    address public rewardToken;                      // slot 2 — nueva, AL FINAL

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

    function setRewardToken(address token) external {
        rewardToken = token;
    }
}
