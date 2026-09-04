// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice AMM de producto constante, sin comisión, sobre un par ETH/TOKEN.
/// @dev El AMM en sí no tiene ningún bug -- es un DEX perfectamente normal.
///      El problema (ver LendingPool.sol y TWAPOracle.sol) es usar su precio
///      instantáneo como si fuera una fuente de verdad fiable.
contract SimpleAMM {
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

    function swapETHForToken() external payable returns (uint256 tokenOut) {
        tokenOut = (reserveToken * msg.value) / (reserveETH + msg.value);
        reserveETH += msg.value;
        reserveToken -= tokenOut;
        token.transfer(msg.sender, tokenOut);
    }

    function swapTokenForETH(uint256 tokenIn) external returns (uint256 ethOut) {
        token.transferFrom(msg.sender, address(this), tokenIn);
        ethOut = (reserveETH * tokenIn) / (reserveToken + tokenIn);
        reserveToken += tokenIn;
        reserveETH -= ethOut;
        (bool success, ) = msg.sender.call{value: ethOut}("");
        require(success, "ETH transfer failed");
    }

    // vulnerable como fuente de precio: es el ratio instantaneo de reservas,
    // manipulable por cualquiera dentro de la misma transaccion
    function getSpotPrice() external view returns (uint256) {
        return (reserveETH * 1e18) / reserveToken; // wei por TOKEN
    }
}
