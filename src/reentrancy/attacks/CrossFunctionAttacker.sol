// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILedgerVault {
    function deposit() external payable;
    function withdraw() external;
    function transferInternal(address to, uint256 amount) external;
    function balances(address account) external view returns (uint256);
}

contract CrossFunctionAttacker {
    ILedgerVault public immutable vault;
    address public immutable accomplice;

    constructor(address _vault, address _accomplice) {
        vault = ILedgerVault(_vault);
        accomplice = _accomplice;
    }

    // Ya implementado: deposita y hace una primera retirada honesta.
    function attack() external payable {
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    // TODO: aquí vive el exploit. Reentrar en withdraw() otra vez también
    // funcionaría (como en el Lab 01) -- pero hay una función hermana que
    // comparte el mismo mapping `balances` y no hace ninguna llamada
    // externa: no está protegida por el mismo motivo que withdraw() sí lo
    // "parece" estar.
    //
    // Pista: consulta vault.balances(address(this)) -- ¿sigue reflejando tu
    // depósito, aunque withdraw() ya te haya enviado el ETH? Si es así, hay
    // una función que te permite mover ese balance a otra dirección antes
    // de que withdraw() termine de ponerlo a 0.
    receive() external payable {
        // completa aquí
    }
}
