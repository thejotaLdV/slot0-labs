// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev Interfaz minima: permite reutilizar RewardsPool sin cambios contra
///      AccessManager (vulnerable) o AccessManagerFixed (corregido) en los tests.
interface IAccessManager {
    function isAdmin(address account) external view returns (bool);
}

/// @notice Protocolo independiente que confía en un AccessManager externo
///         para decidir quién puede vaciarlo en caso de emergencia.
contract RewardsPool {
    IAccessManager public immutable access;
    mapping(address => uint256) public balances;

    constructor(address _access) {
        access = IAccessManager(_access);
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function emergencyWithdraw(address payable to) external {
        require(access.isAdmin(msg.sender), "Not admin");
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}
