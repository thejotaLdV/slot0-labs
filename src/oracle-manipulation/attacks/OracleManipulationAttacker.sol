// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISimpleAMM {
    function swapETHForToken() external payable returns (uint256 tokenOut);
    function swapTokenForETH(uint256 tokenIn) external returns (uint256 ethOut);
}

interface ILendingPool {
    function borrow(uint256 ethAmount) external;
}

contract OracleManipulationAttacker {
    ISimpleAMM public immutable amm;
    ILendingPool public immutable lendingPool;
    IERC20 public immutable token;
    address public immutable owner;

    constructor(address _amm, address _lendingPool, address _token) {
        amm = ISimpleAMM(_amm);
        lendingPool = ILendingPool(_lendingPool);
        token = IERC20(_token);
        owner = msg.sender;
    }

    // TODO: las 4 piezas del ataque, en este orden:
    //   1. Infla el precio del TOKEN metiendo tu ETH (msg.value) en el AMM
    //      (amm.swapETHForToken{value: ...}()) -- guarda cuántos TOKEN recibes.
    //   2. Con el precio ya inflado, pide prestado en lendingPool.borrow(borrowAmount)
    //      -- tu colateral ya estaba depositado antes de llamar a attack().
    //   3. Deshaz el swap del paso 1 para recuperar tu capital: aprueba el TOKEN
    //      recibido para el AMM (token.approve) y llama a amm.swapTokenForETH(...).
    //   4. Envía todo el balance de este contrato a `owner`.
    function attack(uint256 borrowAmount) external payable {
        // completa aquí
    }

    receive() external payable {}
}
