// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Versión corregida: totalShares/reserveETH se actualizan ANTES de la
///         interacción externa, de forma que balance real y contabilidad se
///         mueven siempre juntos — sin ninguna ventana de precio distorsionado.
contract LiquidityPoolFixed is ReentrancyGuard {
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

    function removeLiquidity(uint256 sharesToBurn) external nonReentrant {
        uint256 ethOut = (sharesToBurn * reserveETH) / totalShares;

        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn; // effects ANTES de la interaccion
        reserveETH -= ethOut;

        (bool success, ) = msg.sender.call{value: ethOut}("");
        require(success, "Transfer failed");
    }

    function getVirtualPrice() external view returns (uint256) {
        if (totalShares == 0) return 1e18;
        return (address(this).balance * 1e18) / totalShares;
    }
}
