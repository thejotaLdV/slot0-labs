// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev Interfaz mínima: permite reutilizar LoanManager sin cambios contra
///      LiquidityPool (vulnerable) o LiquidityPoolFixed (corregido) en los tests.
interface IPriceSource {
    function getVirtualPrice() external view returns (uint256);
}

/// @notice Protocolo de crédito independiente que usa el precio de un pool externo
///         como oráculo de colateral. No comparte código ni storage con el pool.
///         Simplificado a propósito: sin transferencia real de shares como colateral,
///         el foco del laboratorio es la manipulación del precio, no el mecanismo
///         de custodia del colateral.
contract LoanManager {
    IPriceSource public immutable pool;
    mapping(address => uint256) public collateralShares;
    mapping(address => uint256) public debt;

    uint256 public constant LIQUIDATION_THRESHOLD = 1.5e18; // 150%

    constructor(address _pool) {
        pool = IPriceSource(_pool);
    }

    function depositCollateral(uint256 sharesAmount) external {
        collateralShares[msg.sender] += sharesAmount;
    }

    function borrow(uint256 amount) external {
        uint256 price = pool.getVirtualPrice();
        uint256 collateralValue = (collateralShares[msg.sender] * price) / 1e18;
        uint256 newDebt = debt[msg.sender] + amount;
        require(
            (collateralValue * 1e18) / newDebt >= LIQUIDATION_THRESHOLD,
            "Insufficient collateral"
        );
        debt[msg.sender] = newDebt;
    }

    function liquidate(address user) external {
        require(debt[user] > 0, "No debt");

        uint256 price = pool.getVirtualPrice();
        uint256 collateralValue = (collateralShares[user] * price) / 1e18;
        uint256 ratio = (collateralValue * 1e18) / debt[user];
        require(ratio < LIQUIDATION_THRESHOLD, "Healthy position");

        uint256 seized = collateralShares[user];
        collateralShares[user] = 0;
        debt[user] = 0;
        collateralShares[msg.sender] += seized;
    }
}
