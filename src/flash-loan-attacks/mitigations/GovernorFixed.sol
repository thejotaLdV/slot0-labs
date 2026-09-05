// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IGovTokenVotes {
    function balanceOf(address account) external view returns (uint256);
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);
}

/// @notice TODO: copia exacta de la versión vulnerable (Governor.sol).
///         Aplica la mitigación tú mismo.
contract GovernorFixed {
    IGovTokenVotes public immutable govToken;
    address public immutable treasury;
    uint256 public constant QUORUM = 500_000e18;

    struct Proposal {
        address target;
        bytes data;
        uint256 votesFor;
        bool executed;
        uint256 snapshotBlock;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public proposalCount;

    constructor(address _govToken, address _treasury) {
        govToken = IGovTokenVotes(_govToken);
        treasury = _treasury;
    }

    // TODO: fija snapshotBlock a un bloque ANTERIOR al actual (block.number - 1)
    // -- el poder de voto se calculará sobre ese bloque, no sobre el
    // instante en que cada uno vote.
    function propose(address target, bytes calldata data) external returns (uint256 id) {
        id = proposalCount++;
        proposals[id] = Proposal({target: target, data: data, votesFor: 0, executed: false, snapshotBlock: 0});
    }

    // TODO: en vez de leer el balance instantáneo, usa
    // govToken.getPastVotes(msg.sender, proposals[id].snapshotBlock).
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
