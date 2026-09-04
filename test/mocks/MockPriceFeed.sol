// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Feed de precio mínimo, compatible con la interfaz de Chainlink,
///         para fixtures de test. Uso exclusivo de los tests.
contract MockPriceFeed {
    int256 private _answer;
    uint256 private _updatedAt;

    constructor(int256 initialAnswer) {
        _answer = initialAnswer;
        _updatedAt = block.timestamp;
    }

    function setAnswer(int256 newAnswer) external {
        _answer = newAnswer;
        _updatedAt = block.timestamp;
    }

    function setUpdatedAt(uint256 newUpdatedAt) external {
        _updatedAt = newUpdatedAt;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, _answer, 0, _updatedAt, 0);
    }
}
