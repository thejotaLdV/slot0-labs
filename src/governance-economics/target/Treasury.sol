// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Tesorería controlada por un Governor. No tiene ningún bug propio.
contract Treasury {
    address public immutable governor;

    constructor(address _governor) {
        governor = _governor;
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "Not governor");
        _;
    }

    function drain(address payable to) external onlyGovernor {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}
