// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice AMM de producto constante, sin comisión, con protección de
///         slippage YA disponible en su propia interfaz. No tiene ningún
///         bug propio -- el problema (ver NaiveSwapper.sol) es no usarla.
contract Pool {
    IERC20 public immutable token;
    uint256 public reserveETH;
    uint256 public reserveToken;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function addLiquidity(uint256 tokenAmount) external payable {
        token.transferFrom(msg.sender, address(this), tokenAmount);
        reserveETH += msg.value;
        reserveToken += tokenAmount;
    }

    function swapExactETHForTokens(uint256 amountOutMin) external payable returns (uint256 amountOut) {
        amountOut = (reserveToken * msg.value) / (reserveETH + msg.value);
        require(amountOut >= amountOutMin, "Slippage exceeded"); // proteccion disponible
        reserveETH += msg.value;
        reserveToken -= amountOut;
        token.transfer(msg.sender, amountOut);
    }

    function swapExactTokensForETH(uint256 tokenIn, uint256 amountOutMin) external returns (uint256 amountOut) {
        token.transferFrom(msg.sender, address(this), tokenIn);
        amountOut = (reserveETH * tokenIn) / (reserveToken + tokenIn);
        require(amountOut >= amountOutMin, "Slippage exceeded");
        reserveToken += tokenIn;
        reserveETH -= amountOut;
        (bool success, ) = msg.sender.call{value: amountOut}("");
        require(success, "ETH transfer failed");
    }
}
