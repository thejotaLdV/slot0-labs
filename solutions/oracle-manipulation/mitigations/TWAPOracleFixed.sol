// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISpotPriceSource {
    function getSpotPrice() external view returns (uint256);
}

contract TWAPOracleFixed {
    ISpotPriceSource public immutable amm;
    uint256 public price0;
    uint256 public price1;
    uint256 public timestampLast;
    uint256 public constant MIN_PERIOD = 30 minutes;

    constructor(address _amm) {
        amm = ISpotPriceSource(_amm);
        price0 = amm.getSpotPrice();
        price1 = price0;
        timestampLast = block.timestamp;
    }

    function update() external {
        require(block.timestamp - timestampLast >= MIN_PERIOD, "Too soon");
        price1 = price0;
        price0 = amm.getSpotPrice();
        timestampLast = block.timestamp;
    }

    function getTWAP() external view returns (uint256) {
        return (price0 + price1) / 2;
    }
}
