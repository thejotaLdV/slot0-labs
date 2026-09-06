// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Pool de préstamos con contabilidad interna de activos totales.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 02 de Gobernanza y economía
///      DeFi. redeem() paga sobre `totalAssets` sin verificar que el pool
///      tenga realmente ese TOKEN disponible en este momento.
contract LendingPool {
    IERC20 public immutable token;
    uint256 public totalShares;
    uint256 public totalAssets; // contabilidad interna
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

    // colateralizacion omitida a proposito: el foco de este lab es la
    // consecuencia contable del impago, no el mecanismo de credito en si
    function borrow(uint256 amount) external {
        require(amount <= token.balanceOf(address(this)), "Insufficient liquidity");
        borrowed[msg.sender] += amount;
        token.transfer(msg.sender, amount);
    }

    // vulnerable: paga sobre totalAssets sin verificar que el pool
    // tenga realmente ese TOKEN disponible en este momento
    function redeem(uint256 shares) external returns (uint256 amount) {
        amount = (shares * totalAssets) / totalShares;
        sharesOf[msg.sender] -= shares;
        totalShares -= shares;
        totalAssets -= amount;
        token.transfer(msg.sender, amount); // revierte solo si YA no queda suficiente TOKEN real
    }

    // existe, pero nada obliga a llamarla cuando un prestamo deja de ser cobrable
    function writeOffBadDebt(address borrower) external {
        uint256 debt = borrowed[borrower];
        borrowed[borrower] = 0;
        totalAssets -= debt;
    }
}
