// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: copia exacta de la versión vulnerable (PermitVault.sol).
///         Aplica la mitigación tú mismo.
contract PermitVaultFixed {
    mapping(address => uint256) public balances;
    mapping(bytes32 => bool) public usedSignatures;

    // secp256k1 order (n)
    uint256 constant SECP256K1_N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

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

    // TODO: antes de aceptar (r, s, v), rechaza cualquier `s` en la mitad
    // "alta" del rango (s > SECP256K1_N / 2) y cualquier `v` distinto de
    // 27/28. Solo una de las dos firmas gemelas cae en el rango bajo -- es
    // exactamente lo que hace OpenZeppelin ECDSA.tryRecover() por dentro.
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
