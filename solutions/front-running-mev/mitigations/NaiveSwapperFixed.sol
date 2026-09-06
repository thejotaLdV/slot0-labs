// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPool {
    function swapExactETHForTokens(uint256 amountOutMin) external payable returns (uint256 amountOut);
}

contract NaiveSwapperFixed {
    IPool public immutable pool;
    uint256 public constant MAX_SLIPPAGE_BPS = 100; // 1%

    constructor(address _pool) {
        pool = IPool(_pool);
    }

    function swap(uint256 expectedOut) external payable {
        uint256 minOut = (expectedOut * (10_000 - MAX_SLIPPAGE_BPS)) / 10_000;
        pool.swapExactETHForTokens{value: msg.value}(minOut);
    }
}
