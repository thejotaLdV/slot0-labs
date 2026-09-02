// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract WalletFixed {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function deposit() external payable {}

    function transfer(address payable to, uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        to.transfer(amount);
    }

    receive() external payable {}
}
