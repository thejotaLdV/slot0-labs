// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice TODO: copia exacta de la versión vulnerable (LendingPool.sol).
///         Aplica la mitigación tú mismo.
contract LendingPoolFixed {
    IERC20 public immutable token;
    uint256 public totalShares;
    uint256 public totalAssets;
    mapping(address => uint256) public sharesOf;
    mapping(address => uint256) public borrowed;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function deposit(uint256 amount) external returns (uint256 shares) {
        shares = totalShares == 0 ? amount : (amount * totalShares) / totalAssets;
        token.transferFrom(msg.sender, address(this), amount);
        totalAssets += amount;
        sharesOf[msg.sender] += shares;
        totalShares += shares;
    }

    function borrow(uint256 amount) external {
        require(amount <= token.balanceOf(address(this)), "Insufficient liquidity");
        borrowed[msg.sender] += amount;
        token.transfer(msg.sender, amount);
    }

    // TODO: calcula `amount` igual que antes, pero nunca prometas más de lo
    // que el pool realmente tiene ahora mismo -- si amount supera el balance
    // real (token.balanceOf(address(this))), recorta amount a ese balance.
    function redeem(uint256 shares) external returns (uint256 amount) {
        amount = (shares * totalAssets) / totalShares;
        sharesOf[msg.sender] -= shares;
        totalShares -= shares;
        totalAssets -= amount;
        token.transfer(msg.sender, amount);
    }

    function writeOffBadDebt(address borrower) external {
        uint256 debt = borrowed[borrower];
        borrowed[borrower] = 0;
        totalAssets -= debt;
    }
}
