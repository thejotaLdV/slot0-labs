// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Gobernanza on-chain con delegación de voto.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 01 de Gobernanza y economía
///      DeFi. delegate() suma poder de voto al nuevo delegado pero nunca
///      resta el que ya se le había dado a un delegado anterior -- y el
///      balance propio del delegante sigue intacto y sigue pudiendo votar con él.
contract GovernorWithDelegation {
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

    // vulnerable: suma poder de voto al nuevo delegado, pero nunca resta
    // el que ya se le habia dado a un delegado anterior
    function delegate(address to) external {
        delegatee[msg.sender] = to;
        delegatedPower[to] += govToken.balanceOf(msg.sender);
    }

    // vulnerable: suma balance propio + poder delegado recibido, sin
    // comprobar si msg.sender ya delego SU balance a otra direccion
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
