// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice TODO: copia exacta de la versión vulnerable (GovernorWithDelegation.sol).
///         Aplica la mitigación tú mismo.
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

    // TODO: antes de sobreescribir delegatee[msg.sender], si ya había un
    // delegado anterior distinto de address(0), deshaz esa delegación
    // restando el mismo importe de delegatedPower[ese delegado anterior].
    function delegate(address to) external {
        delegatee[msg.sender] = to;
        delegatedPower[to] += govToken.balanceOf(msg.sender);
    }

    // TODO: el balance propio de msg.sender solo debería contar aquí si
    // msg.sender NO ha delegado a nadie (delegatee[msg.sender] == address(0)).
    // Si ha delegado, su balance ya cuenta a través de delegatedPower del
    // delegado -- sumarlo aquí también lo cuenta dos veces.
    function vote(uint256 id) external {
        require(!hasVoted[id][msg.sender], "Already voted");
        hasVoted[id][msg.sender] = true;
        uint256 weight = govToken.balanceOf(msg.sender) + delegatedPower[msg.sender];
        proposals[id].votesFor += weight;
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
