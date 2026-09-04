// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISpotPriceSource {
    function getSpotPrice() external view returns (uint256);
}

/// @notice Pretende suavizar el precio spot de un AMM promediando dos
///         lecturas -- pero no es un TWAP real.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 02 de Manipulación de
///      oráculos. No exige ningún tiempo mínimo entre actualizaciones.
contract TWAPOracle {
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

    // vulnerable: cualquiera puede llamarla, tantas veces como quiera,
    // sin exigir que haya pasado ningun tiempo minimo desde la ultima vez
    function update() external {
        price1 = price0;
        price0 = amm.getSpotPrice();
        timestampLast = block.timestamp;
    }

    // vulnerable: promedia dos lecturas puntuales sin ponderar por el
    // tiempo real transcurrido entre ellas — esto NO es un TWAP real
    function getTWAP() external view returns (uint256) {
        return (price0 + price1) / 2;
    }
}
