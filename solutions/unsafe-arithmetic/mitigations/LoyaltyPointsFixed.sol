// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract LoyaltyPointsFixed {
    mapping(address => uint256) public points;
    uint256 public constant CLAIM_COST = 100;

    function earn(uint256 amount) external payable {
        points[msg.sender] += amount;
    }

    function claimReward(address payable to) external {
        require(points[msg.sender] >= CLAIM_COST, "Insufficient points");

        points[msg.sender] -= CLAIM_COST;

        (bool success, ) = to.call{value: 0.01 ether}("");
        require(success, "Transfer failed");
    }

    function fund() external payable {}
}
