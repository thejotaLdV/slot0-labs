// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISpotPriceSource {
    function getSpotPrice() external view returns (uint256);
}

/// @notice TODO: copia exacta de la versión vulnerable (TWAPOracle.sol).
///         Aplica la mitigación tú mismo.
contract TWAPOracleFixed {
    ISpotPriceSource public immutable amm;
    uint256 public price0;
    uint256 public price1;
    uint256 public timestampLast;

    constructor(address _amm) {
        amm = ISpotPriceSource(_amm);
        price0 = amm.getSpotPrice();
        price1 = price0;
        timestampLast = block.timestamp;
    }

    // TODO: exige que haya pasado un tiempo minimo desde timestampLast antes
    // de permitir otra actualizacion. Sin esto, un atacante puede llamar a
    // update() varias veces en la misma transaccion y expulsar el precio
    // real del promedio.
    function update() external {
        price1 = price0;
        price0 = amm.getSpotPrice();
        timestampLast = block.timestamp;
    }

    function getTWAP() external view returns (uint256) {
        return (price0 + price1) / 2;
    }
}
