// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice TODO: copia exacta de la versión vulnerable (RewardStaking.sol).
///         Aplica la mitigación tú mismo.
contract RewardStakingFixed {
    IERC20 public immutable stakeToken;
    uint256 public totalStaked;
    mapping(address => uint256) public stakedOf;
    uint256 public rewardPool;

    constructor(address _stakeToken) {
        stakeToken = IERC20(_stakeToken);
    }

    // TODO: registra en algún sitio CUÁNDO empezó a hacer staking cada
    // usuario (un mapping nuevo con block.timestamp basta).
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

    // TODO: exige que haya pasado un tiempo mínimo desde que el usuario
    // empezó a hacer staking, usando el timestamp que registraste arriba.
    function claimReward() external {
        uint256 share = (rewardPool * stakedOf[msg.sender]) / totalStaked;
        rewardPool -= share;
        (bool success, ) = msg.sender.call{value: share}("");
        require(success, "Transfer failed");
    }
}
