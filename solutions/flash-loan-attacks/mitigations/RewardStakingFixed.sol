// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardStakingFixed {
    IERC20 public immutable stakeToken;
    uint256 public totalStaked;
    mapping(address => uint256) public stakedOf;
    uint256 public rewardPool;
    mapping(address => uint256) public stakeTimestamp;
    uint256 public constant MIN_STAKE_DURATION = 1 days;

    constructor(address _stakeToken) {
        stakeToken = IERC20(_stakeToken);
    }

    function stake(uint256 amount) external {
        stakeToken.transferFrom(msg.sender, address(this), amount);
        stakedOf[msg.sender] += amount;
        totalStaked += amount;
        stakeTimestamp[msg.sender] = block.timestamp;
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
        require(block.timestamp - stakeTimestamp[msg.sender] >= MIN_STAKE_DURATION, "Too soon");
        uint256 share = (rewardPool * stakedOf[msg.sender]) / totalStaked;
        rewardPool -= share;
        (bool success, ) = msg.sender.call{value: share}("");
        require(success, "Transfer failed");
    }
}
