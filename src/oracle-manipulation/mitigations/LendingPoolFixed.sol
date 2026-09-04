// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Interfaz minima compatible con Chainlink AggregatorV3Interface --
///      no depende del paquete real, solo de su forma, para no anadir una
///      dependencia nueva al repositorio. En producción se usaría el feed
///      real de Chainlink (u otro oráculo con agregación externa).
interface IPriceFeed {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/// @notice TODO: copia de LendingPool.sol, pero pensada para recibir un
///         oráculo externo en vez del AMM. Aplica la mitigación tú mismo.
contract LendingPoolFixed {
    IPriceFeed public immutable priceFeed;
    IERC20 public immutable token;
    mapping(address => uint256) public collateralToken;
    mapping(address => uint256) public borrowedETH;
    uint256 public constant LTV_BPS = 7000; // 70%
    uint256 public constant MAX_STALENESS = 1 hours;

    constructor(address _priceFeed, address _token) {
        priceFeed = IPriceFeed(_priceFeed);
        token = IERC20(_token);
    }

    function depositCollateral(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        collateralToken[msg.sender] += amount;
    }

    // TODO: sigue usando priceSource.getSpotPrice() -- el mismo bug que
    // LendingPool.sol. Sustitúyelo por una lectura de priceFeed.latestRoundData(),
    // comprobando que el precio es positivo y que no lleva más de MAX_STALENESS
    // sin actualizarse.
    function borrow(uint256 ethAmount) external {
        uint256 price = 0; // placeholder -- sustituye por la lectura real del oraculo
        uint256 collateralValueETH = (collateralToken[msg.sender] * price) / 1e18;
        uint256 maxBorrow = (collateralValueETH * LTV_BPS) / 10000;
        require(borrowedETH[msg.sender] + ethAmount <= maxBorrow, "Exceeds LTV");

        borrowedETH[msg.sender] += ethAmount;
        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "ETH transfer failed");
    }
}
