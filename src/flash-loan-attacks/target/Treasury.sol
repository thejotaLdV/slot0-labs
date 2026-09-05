// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Tesorería controlada por un Governor. No tiene ningún bug propio
///         -- confía correctamente en que solo su Governor puede vaciarla.
contract Treasury {
    address public immutable governor;

    constructor(address _governor) {
        governor = _governor;
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "Not governor");
        _;
    }

    function transferOut(address payable to, uint256 amount) external onlyGovernor {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}
