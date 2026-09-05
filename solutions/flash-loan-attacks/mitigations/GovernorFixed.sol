// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IGovTokenVotes {
    function balanceOf(address account) external view returns (uint256);
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);
}

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

    function propose(address target, bytes calldata data) external returns (uint256 id) {
        id = proposalCount++;
        proposals[id] = Proposal({
            target: target,
            data: data,
            votesFor: 0,
            executed: false,
            snapshotBlock: block.number - 1
        });
    }

    function vote(uint256 id) external {
        require(!hasVoted[id][msg.sender], "Already voted");
        hasVoted[id][msg.sender] = true;
        uint256 weight = govToken.getPastVotes(msg.sender, proposals[id].snapshotBlock);
        proposals[id].votesFor += weight;
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
