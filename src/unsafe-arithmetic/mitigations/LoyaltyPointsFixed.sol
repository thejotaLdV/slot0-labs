// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: copia exacta de la versión vulnerable (LoyaltyPoints.sol).
///         Aplica la mitigación tú mismo.
contract LoyaltyPointsFixed {
    mapping(address => uint256) public points;
    uint256 public constant CLAIM_COST = 100;

    function earn(uint256 amount) external payable {
        points[msg.sender] += amount;
    }

    // TODO: dos cambios -- exige points[msg.sender] >= CLAIM_COST (no solo
    // > 0), y quita el bloque unchecked de la resta (con la comprobación ya
    // corregida, la protección automática del compilador es una red
    // adicional, no la única barrera).
    function claimReward(address payable to) external {
        require(points[msg.sender] > 0, "No points");

        unchecked {
            points[msg.sender] -= CLAIM_COST;
        }

        (bool success, ) = to.call{value: 0.01 ether}("");
        require(success, "Transfer failed");
    }

    function fund() external payable {}
}
