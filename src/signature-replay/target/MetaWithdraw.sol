// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Retiradas autorizadas por firma fuera de cadena (meta-transacciones).
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 01 de Firma y replay (SWC-121).
///      Nada marca una firma (ni la autorización que representa) como usada
///      -- se puede reenviar tantas veces como el balance de `owner` lo permita.
contract MetaWithdraw {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawWithSignature(
        address owner,
        uint256 amount,
        address payable to,
        bytes memory signature
    ) external {
        bytes32 messageHash = keccak256(abi.encodePacked(owner, amount, to));
        bytes32 ethSignedHash = toEthSignedMessageHash(messageHash);
        require(recoverSigner(ethSignedHash, signature) == owner, "Invalid signature");

        require(balances[owner] >= amount, "Insufficient balance");
        balances[owner] -= amount;
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recoverSigner(bytes32 ethSignedHash, bytes memory signature) public pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return ecrecover(ethSignedHash, v, r, s);
    }
}
