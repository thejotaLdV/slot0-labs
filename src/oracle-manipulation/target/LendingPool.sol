// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Interfaz minima: permite que LendingPool use cualquier fuente de
///      precio -- el AMM vulnerable, o un oraculo externo en la mitigacion.
interface IPriceSource {
    function getSpotPrice() external view returns (uint256);
}

/// @notice Protocolo de préstamos que acepta TOKEN como colateral para
///         prestar ETH, valorando el colateral con un precio externo.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 01 de Manipulación de
///      oráculos (OWASP SC03:2026). La fuente de precio es el spot
///      instantáneo de un AMM, manipulable dentro de una única transacción.
contract LendingPool {
    IPriceSource public immutable priceSource;
    IERC20 public immutable token;
    mapping(address => uint256) public collateralToken;
    mapping(address => uint256) public borrowedETH;
    uint256 public constant LTV_BPS = 7000; // 70%

    constructor(address _priceSource, address _token) {
        priceSource = IPriceSource(_priceSource);
        token = IERC20(_token);
    }

    function depositCollateral(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        collateralToken[msg.sender] += amount;
    }

    // vulnerable: usa el precio spot instantaneo del AMM como si fuera de fiar
    function borrow(uint256 ethAmount) external {
        uint256 price = priceSource.getSpotPrice();
        uint256 collateralValueETH = (collateralToken[msg.sender] * price) / 1e18;
        uint256 maxBorrow = (collateralValueETH * LTV_BPS) / 10000;
        require(borrowedETH[msg.sender] + ethAmount <= maxBorrow, "Exceeds LTV");

        borrowedETH[msg.sender] += ethAmount;
        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "ETH transfer failed");
    }
}
