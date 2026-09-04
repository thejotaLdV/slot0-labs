// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Vault de un solo activo al estilo ERC-4626: emite shares
///         proporcionales al valor depositado.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 03 de Manipulación de
///      oráculos. totalAssets() lee el balance del contrato en vivo, que
///      cualquiera puede inflar con una transferencia directa.
contract SharePriceVault {
    IERC20 public immutable asset;
    uint256 public totalShares;
    mapping(address => uint256) public sharesOf;

    constructor(address _asset) {
        asset = IERC20(_asset);
    }

    // vulnerable: lee el balance EN VIVO del contrato, no una contabilidad
    // interna que solo depositos/retiradas puedan modificar
    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function deposit(uint256 amount) external returns (uint256 shares) {
        if (totalShares == 0) {
            shares = amount; // primer deposito: 1:1
        } else {
            shares = (amount * totalShares) / totalAssets();
        }
        asset.transferFrom(msg.sender, address(this), amount);
        sharesOf[msg.sender] += shares;
        totalShares += shares;
    }

    function redeem(uint256 shares) external returns (uint256 amount) {
        amount = (shares * totalAssets()) / totalShares;
        sharesOf[msg.sender] -= shares;
        totalShares -= shares;
        asset.transfer(msg.sender, amount);
    }

    function pricePerShare() external view returns (uint256) {
        if (totalShares == 0) return 1e18;
        return (totalAssets() * 1e18) / totalShares;
    }
}
