// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IGovToken {
    function balanceOf(address account) external view returns (uint256);
}

/// @notice Gobernanza on-chain simplificada: proponer, votar, ejecutar.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 02 de Flash Loan Attacks.
///      El peso de voto es el balance INSTANTÁNEO de govToken (sin snapshot),
///      y no hay ningún timelock entre alcanzar quorum y poder ejecutar.
contract Governor {
    IGovToken public immutable govToken;
    address public immutable treasury;
    uint256 public constant QUORUM = 500_000e18;

    struct Proposal {
        address target;
        bytes data;
        uint256 votesFor;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public proposalCount;

    constructor(address _govToken, address _treasury) {
        govToken = IGovToken(_govToken);
        treasury = _treasury;
    }

    function propose(address target, bytes calldata data) external returns (uint256 id) {
        id = proposalCount++;
        proposals[id] = Proposal({target: target, data: data, votesFor: 0, executed: false});
    }

    function vote(uint256 id) external {
        require(!hasVoted[id][msg.sender], "Already voted");
        hasVoted[id][msg.sender] = true;
        proposals[id].votesFor += govToken.balanceOf(msg.sender);
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
