// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceFeed {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract LendingPoolFixed {
    IPriceFeed public immutable priceFeed;
    IERC20 public immutable token;
    mapping(address => uint256) public collateralToken;
    mapping(address => uint256) public borrowedETH;
    uint256 public constant LTV_BPS = 7000;
    uint256 public constant MAX_STALENESS = 1 hours;

    constructor(address _priceFeed, address _token) {
        priceFeed = IPriceFeed(_priceFeed);
        token = IERC20(_token);
    }

    function depositCollateral(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        collateralToken[msg.sender] += amount;
    }

    function borrow(uint256 ethAmount) external {
        (, int256 answer, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        require(answer > 0, "Invalid price");
        require(block.timestamp - updatedAt < MAX_STALENESS, "Stale price");

        uint256 price = uint256(answer);
        uint256 collateralValueETH = (collateralToken[msg.sender] * price) / 1e18;
        uint256 maxBorrow = (collateralValueETH * LTV_BPS) / 10000;
        require(borrowedETH[msg.sender] + ethAmount <= maxBorrow, "Exceeds LTV");

        borrowedETH[msg.sender] += ethAmount;
        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "ETH transfer failed");
    }
}
