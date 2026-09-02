// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: copia exacta de la versión vulnerable (Wallet.sol).
///         Aplica la mitigación tú mismo.
contract WalletFixed {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function deposit() external payable {}

    // TODO: ¿qué variable global debería comprobarse aquí en vez de tx.origin?
    // Pista: tx.origin siempre es la cuenta que firmó la transacción original,
    // aunque haya varios contratos intermedios reenviando la llamada. msg.sender
    // es quien llama directamente a ESTA función.
    function transfer(address payable to, uint256 amount) external {
        require(tx.origin == owner, "Not owner");
        to.transfer(amount);
    }

    receive() external payable {}
}
