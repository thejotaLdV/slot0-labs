// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: misma funcionalidad que VaultLogicV2.sol, pero con el
///         layout de storage corregido. Aplica la mitigación tú mismo.
contract VaultLogicV2Fixed {
    // TODO: reordena las variables de estado de abajo para que
    // totalDeposits siga en el slot 0 y balances en el slot 1 -- IGUAL que
    // en VaultLogicV1.sol -- y añade rewardToken AL FINAL, en un slot nuevo.
    address public rewardToken;
    uint256 public totalDeposits;
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function setRewardToken(address token) external {
        rewardToken = token;
    }
}
