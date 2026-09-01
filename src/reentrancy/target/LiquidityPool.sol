// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Pool de liquidez de un solo activo (ETH), simplificado.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 03 de la categoría Reentrancy.
///      `getVirtualPrice()` lee `address(this).balance` en vivo; durante el
///      callback de `removeLiquidity()` ese balance ya bajó pero `totalShares`
///      todavía no, produciendo un precio transitoriamente deprimido.
contract LiquidityPool {
    mapping(address => uint256) public shares;
    uint256 public totalShares;
    uint256 public reserveETH;

    function addLiquidity() external payable {
        uint256 newShares =
            totalShares == 0 ? msg.value : (msg.value * totalShares) / reserveETH;
        shares[msg.sender] += newShares;
        totalShares += newShares;
        reserveETH += msg.value;
    }

    function removeLiquidity(uint256 sharesToBurn) external {
        uint256 ethOut = (sharesToBurn * reserveETH) / totalShares;

        (bool success, ) = msg.sender.call{value: ethOut}(""); // interaction primero

        require(success, "Transfer failed");

        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn; // effect llega despues
        reserveETH -= ethOut;
    }

    function getVirtualPrice() external view returns (uint256) {
        if (totalShares == 0) return 1e18;
        return (address(this).balance * 1e18) / totalShares;
    }
}
