// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice TODO: copia exacta de la versión vulnerable (LiquidityPool.sol).
///         Aplica la mitigación tú mismo.
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

    // TODO: mismo bug que la versión vulnerable -- reordena a CEI y añade
    // nonReentrant. Fíjate en qué tres líneas hay que mover, no solo cuál.
    function removeLiquidity(uint256 sharesToBurn) external {
        uint256 ethOut = (sharesToBurn * reserveETH) / totalShares;

        (bool success, ) = msg.sender.call{value: ethOut}("");
        require(success, "Transfer failed");

        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;
        reserveETH -= ethOut;
    }

    function getVirtualPrice() external view returns (uint256) {
        if (totalShares == 0) return 1e18;
        return (address(this).balance * 1e18) / totalShares;
    }
}
