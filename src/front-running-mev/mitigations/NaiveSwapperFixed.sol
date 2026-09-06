// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPool {
    function swapExactETHForTokens(uint256 amountOutMin) external payable returns (uint256 amountOut);
}

/// @notice TODO: copia exacta de la versión vulnerable (NaiveSwapper.sol).
///         Aplica la mitigación tú mismo.
contract NaiveSwapperFixed {
    IPool public immutable pool;
    uint256 public constant MAX_SLIPPAGE_BPS = 100; // 1%

    constructor(address _pool) {
        pool = IPool(_pool);
    }

    // TODO: calcula minOut a partir de `expectedOut` (el resultado que el
    // usuario espera, calculado off-chain a precio justo) permitiendo como
    // mucho MAX_SLIPPAGE_BPS de desviación, y pásaselo a swapExactETHForTokens
    // en vez del 0 fijo de la version vulnerable.
    function swap(uint256 expectedOut) external payable {
        pool.swapExactETHForTokens{value: msg.value}(0);
    }
}
