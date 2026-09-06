// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 02 de Delegatecall & Storage
///      Collisions. Variable NUEVA insertada al PRINCIPIO en vez de al final:
///      desplaza el layout completo respecto a VaultLogicV1.
contract VaultLogicV2 {
    address public rewardToken;                     // slot 0 (nueva)
    uint256 public totalDeposits;                    // slot 1 (desplazada, antes slot 0)
    mapping(address => uint256) public balances;     // slot 2 (desplazada, antes slot 1)

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
