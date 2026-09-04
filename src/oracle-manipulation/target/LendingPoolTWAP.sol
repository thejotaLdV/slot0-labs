// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Interfaz minima: permite que LendingPoolTWAP funcione, sin cambios,
///      tanto contra TWAPOracle (vulnerable) como contra TWAPOracleFixed.
interface ITWAPSource {
    function getTWAP() external view returns (uint256);
}

/// @notice Idéntico a LendingPool.sol del Lab 01, cambiando únicamente la
///         fuente de precio: en vez del spot instantáneo, usa un "TWAP".
contract LendingPoolTWAP {
    ITWAPSource public immutable twapSource;
    IERC20 public immutable token;
    mapping(address => uint256) public collateralToken;
    mapping(address => uint256) public borrowedETH;
    uint256 public constant LTV_BPS = 7000;

    constructor(address _twapSource, address _token) {
        twapSource = ITWAPSource(_twapSource);
        token = IERC20(_token);
    }

    function depositCollateral(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        collateralToken[msg.sender] += amount;
    }

    function borrow(uint256 ethAmount) external {
        uint256 price = twapSource.getTWAP();
        uint256 collateralValueETH = (collateralToken[msg.sender] * price) / 1e18;
        uint256 maxBorrow = (collateralValueETH * LTV_BPS) / 10000;
        require(borrowedETH[msg.sender] + ethAmount <= maxBorrow, "Exceeds LTV");

        borrowedETH[msg.sender] += ethAmount;
        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "ETH transfer failed");
    }
}
