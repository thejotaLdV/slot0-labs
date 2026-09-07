// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Igual que MetaWithdraw.sol, pero SÍ marca la firma como usada.
/// @dev VULNERABLE A PROPÓSITO — ver Laboratorio 02 de Firma y replay
///      (SWC-117 / SWC-121 variante). Marca la FIRMA (su hash) como usada,
///      no la AUTORIZACIÓN que representa -- y una firma ECDSA válida tiene
///      una "gemela" maleable (mismo r, s' = n - s, v invertido) que
///      recupera la MISMA dirección pero produce un hash distinto.
contract PermitVault {
    mapping(address => uint256) public balances;
    mapping(bytes32 => bool) public usedSignatures;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawWithSignature(
        address owner,
        uint256 amount,
        address payable to,
        bytes memory signature
    ) external {
        bytes32 sigHash = keccak256(signature);
        require(!usedSignatures[sigHash], "Signature already used");
        usedSignatures[sigHash] = true;

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
