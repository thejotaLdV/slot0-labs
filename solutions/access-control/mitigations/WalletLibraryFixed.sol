// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract WalletLibraryFixed {
    address public owner;
    mapping(address => uint256) public balances;
    bool private initialized;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function initWallet(address _owner) external {
        require(!initialized, "Already initialized");
        initialized = true;
        owner = _owner;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function kill(address payable to) external onlyOwner {
        selfdestruct(to);
    }
}
