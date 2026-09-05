// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Prestamista de flash loans de un solo activo, sin comision.
/// @dev No es vulnerable por si mismo -- es la herramienta que hace posible
///      manipular, sin capital propio, los contratos de estos dos laboratorios.
interface IFlashBorrower {
    function onFlashLoan(uint256 amount, bytes calldata data) external;
}

contract FlashLender {
    IERC20 public immutable token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function flashLoan(uint256 amount, bytes calldata data) external {
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient liquidity");

        token.transfer(msg.sender, amount);
        IFlashBorrower(msg.sender).onFlashLoan(amount, data);

        require(token.balanceOf(address(this)) >= balanceBefore, "Loan not repaid");
    }
}
