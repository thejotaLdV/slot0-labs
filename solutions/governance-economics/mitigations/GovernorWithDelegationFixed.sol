// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GovernorWithDelegationFixed {
    IERC20 public immutable govToken;
    uint256 public constant QUORUM = 300_000e18;

    mapping(address => address) public delegatee;
    mapping(address => uint256) public delegatedPower;

    struct Proposal {
        address target;
        bytes data;
        uint256 votesFor;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public proposalCount;

    constructor(address _govToken) {
        govToken = IERC20(_govToken);
    }

    function delegate(address to) external {
        address current = delegatee[msg.sender];
        uint256 amount = govToken.balanceOf(msg.sender);

        if (current != address(0)) {
            delegatedPower[current] -= amount;
        }
        delegatee[msg.sender] = to;
        delegatedPower[to] += amount;
    }

    function vote(uint256 id) external {
        require(!hasVoted[id][msg.sender], "Already voted");
        hasVoted[id][msg.sender] = true;
        uint256 ownWeight = delegatee[msg.sender] == address(0) ? govToken.balanceOf(msg.sender) : 0;
        proposals[id].votesFor += ownWeight + delegatedPower[msg.sender];
    }

    function propose(address target, bytes calldata data) external returns (uint256 id) {
        id = proposalCount++;
        proposals[id] = Proposal({target: target, data: data, votesFor: 0, executed: false});
    }

    function execute(uint256 id) external {
        Proposal storage p = proposals[id];
        require(!p.executed, "Already executed");
        require(p.votesFor >= QUORUM, "Quorum not reached");
        p.executed = true;
        (bool success, ) = p.target.call(p.data);
        require(success, "Execution failed");
    }
}
