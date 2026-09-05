// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Reparte un pool de recompensas en ETH proporcionalmente al stake.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 01 de Flash Loan Attacks.
///      Reparte según el stake INSTANTÁNEO en el momento del claim, sin
///      ningún periodo mínimo de permanencia ni ponderación por tiempo.
contract RewardStaking {
    IERC20 public immutable stakeToken;
    uint256 public totalStaked;
    mapping(address => uint256) public stakedOf;
    uint256 public rewardPool;

    constructor(address _stakeToken) {
        stakeToken = IERC20(_stakeToken);
    }

    function stake(uint256 amount) external {
        stakeToken.transferFrom(msg.sender, address(this), amount);
        stakedOf[msg.sender] += amount;
        totalStaked += amount;
    }

    function unstake(uint256 amount) external {
        stakedOf[msg.sender] -= amount;
        totalStaked -= amount;
        stakeToken.transfer(msg.sender, amount);
    }

    function addRewards() external payable {
        rewardPool += msg.value;
    }

    function claimReward() external {
        uint256 share = (rewardPool * stakedOf[msg.sender]) / totalStaked;
        rewardPool -= share;
        (bool success, ) = msg.sender.call{value: share}("");
        require(success, "Transfer failed");
    }
}
