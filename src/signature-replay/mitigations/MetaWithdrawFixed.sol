// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice TODO: copia exacta de la versión vulnerable (MetaWithdraw.sol),
///         con la firma de withdrawWithSignature() ya actualizada para
///         aceptar un nonce -- pero el cuerpo todavía no lo usa de verdad.
contract MetaWithdrawFixed {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public nonces;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // TODO: exige que `nonce` coincida con nonces[owner], incluye el nonce
    // (y address(this), para que la firma no sirva en otro contrato) dentro
    // de messageHash, y consume el nonce ANTES de la llamada externa --
    // igual que el balance, es un "effect" que debe ir antes de la
    // "interaction". De momento el parametro existe pero no se usa para nada.
    function withdrawWithSignature(
        address owner,
        uint256 amount,
        address payable to,
        uint256 nonce,
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
