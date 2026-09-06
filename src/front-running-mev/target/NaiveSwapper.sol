// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPool {
    function swapExactETHForTokens(uint256 amountOutMin) external payable returns (uint256 amountOut);
}

/// @notice Envoltorio de conveniencia sobre Pool.sol.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 02 de Front-running & MEV.
///      Acepta CUALQUIER resultado del swap, sin calcular un mínimo
///      razonable -- ignora una protección que el propio Pool ya ofrece.
contract NaiveSwapper {
    IPool public immutable pool;

    constructor(address _pool) {
        pool = IPool(_pool);
    }

    function swap() external payable {
        pool.swapExactETHForTokens{value: msg.value}(0);
    }
}
