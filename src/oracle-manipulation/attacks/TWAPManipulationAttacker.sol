// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISimpleAMM {
    function swapETHForToken() external payable returns (uint256 tokenOut);
    function swapTokenForETH(uint256 tokenIn) external returns (uint256 ethOut);
}

interface ITWAPOracle {
    function update() external;
}

interface ILendingPoolTWAP {
    function borrow(uint256 ethAmount) external;
}

contract TWAPManipulationAttacker {
    ISimpleAMM public immutable amm;
    ITWAPOracle public immutable twapOracle;
    ILendingPoolTWAP public immutable lendingPool;
    IERC20 public immutable token;
    address public immutable owner;

    constructor(address _amm, address _twap, address _lendingPool, address _token) {
        amm = ISimpleAMM(_amm);
        twapOracle = ITWAPOracle(_twap);
        lendingPool = ILendingPoolTWAP(_lendingPool);
        token = IERC20(_token);
        owner = msg.sender;
    }

    // TODO: el "TWAP" de este oráculo solo promedia sus DOS últimas lecturas,
    // sin importar cuánto tiempo pasó entre ellas -- puedes actualizarlo dos
    // veces seguidas, en la misma transacción, y expulsar el precio real
    // del promedio por completo. Con msg.value dividido en dos partes:
    //   1. Primer swap (una fracción de msg.value) + twapOracle.update()
    //      -- el precio real queda diluido a la mitad.
    //   2. Segundo swap (el resto del balance de este contrato) +
    //      twapOracle.update() -- ahora AMBAS lecturas son el precio ya
    //      manipulado: el real ha desaparecido del promedio.
    //   3. lendingPool.borrow(borrowAmount) con el "TWAP" ya inservible.
    //   4. Deshacer ambos swaps (suma total de tokens recibidos) para
    //      recuperar el capital, y enviar el balance final a `owner`.
    function attack(uint256 borrowAmount) external payable {
        // completa aquí
    }

    receive() external payable {}
}
