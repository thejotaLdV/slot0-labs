// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AccessManagerFixed {
    mapping(address => bool) public isAdmin;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not admin");
        _;
    }

    constructor() {
        isAdmin[msg.sender] = true;
    }

    function grantAdmin(address account) external onlyAdmin {
        isAdmin[account] = true;
    }

    function revokeAdmin(address account) external onlyAdmin {
        isAdmin[account] = false;
    }
}
