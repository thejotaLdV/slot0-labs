// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SharePriceVaultFixed {
    IERC20 public immutable asset;
    uint256 public totalShares;
    mapping(address => uint256) public sharesOf;
    uint256 private _totalAssetsTracked;

    constructor(address _asset) {
        asset = IERC20(_asset);
    }

    function totalAssets() public view returns (uint256) {
        return _totalAssetsTracked;
    }

    function deposit(uint256 amount) external returns (uint256 shares) {
        if (totalShares == 0) {
            shares = amount;
        } else {
            shares = (amount * totalShares) / totalAssets();
        }
        asset.transferFrom(msg.sender, address(this), amount);
        _totalAssetsTracked += amount;
        sharesOf[msg.sender] += shares;
        totalShares += shares;
    }

    function redeem(uint256 shares) external returns (uint256 amount) {
        amount = (shares * totalAssets()) / totalShares;
        sharesOf[msg.sender] -= shares;
        totalShares -= shares;
        _totalAssetsTracked -= amount;
        asset.transfer(msg.sender, amount);
    }

    function pricePerShare() external view returns (uint256) {
        if (totalShares == 0) return 1e18;
        return (totalAssets() * 1e18) / totalShares;
    }
}
