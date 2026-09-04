// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice TODO: copia exacta de la versión vulnerable (SharePriceVault.sol).
///         Aplica la mitigación tú mismo.
contract SharePriceVaultFixed {
    IERC20 public immutable asset;
    uint256 public totalShares;
    mapping(address => uint256) public sharesOf;

    constructor(address _asset) {
        asset = IERC20(_asset);
    }

    // TODO: en vez de leer asset.balanceOf(address(this)) en vivo, esta
    // función debería devolver una contabilidad interna que SOLO deposit()
    // y redeem() puedan modificar. Necesitas una variable de estado nueva
    // (un contador propio de "activos totales") y actualizarla en ambas
    // funciones de abajo -- una donación directa por transferencia ya no
    // debería mover este número.
    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function deposit(uint256 amount) external returns (uint256 shares) {
        if (totalShares == 0) {
            shares = amount;
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
