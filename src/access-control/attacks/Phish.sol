// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev Interfaz mínima común a Wallet y WalletFixed, para poder reutilizar
///      este mismo contrato señuelo contra ambas versiones en los tests.
interface IWallet {
    function deposit() external payable;
    function transfer(address payable to, uint256 amount) external;
}

contract Phish {
    IWallet public immutable wallet;
    address payable public immutable attacker;

    constructor(address _wallet, address payable _attacker) {
        wallet = IWallet(_wallet);
        attacker = _attacker;
    }

    // TODO: la víctima (el owner de la wallet) es quien va a llamar a esta
    // función directamente, con el nombre que le pongas de señuelo. Desde
    // aquí, haz que la wallet transfiera su balance completo al atacante.
    //
    // Pista: msg.sender de esta llamada a wallet.transfer(...) será la
    // dirección de ESTE contrato (Phish), no la de quien te llamó a ti --
    // pero tx.origin seguirá siendo la víctima que firmó la transacción.
    function claimReward() external {
        // completa aquí
    }
}
