// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {VaultProxy} from "../../src/delegatecall-storage-collisions/target/VaultProxy.sol";
import {VaultLogicV1} from "../../src/delegatecall-storage-collisions/target/VaultLogicV1.sol";
import {VaultLogicV2} from "../../src/delegatecall-storage-collisions/target/VaultLogicV2.sol";
import {VaultLogicV2Fixed} from "../../src/delegatecall-storage-collisions/mitigations/VaultLogicV2Fixed.sol";

interface IVault {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balances(address account) external view returns (uint256);
    function totalDeposits() external view returns (uint256);
}

contract DelegatecallStorage02Test is Test {
    VaultProxy proxy;
    VaultLogicV1 v1;

    VaultProxy proxyFixed;
    VaultLogicV1 v1Fixed;

    address victim = makeAddr("victim");
    address attacker = makeAddr("attacker");

    function setUp() public {
        v1 = new VaultLogicV1();
        proxy = new VaultProxy(address(v1));

        v1Fixed = new VaultLogicV1();
        proxyFixed = new VaultProxy(address(v1Fixed));
    }

    /// @dev Este exploit no necesita ningún contrato atacante ni siquiera un
    ///      atacante activo -- es el propio equipo, con buena intención,
    ///      quien rompe su contabilidad al desplegar V2. La lección de este
    ///      laboratorio es leer el layout de storage, no programar un ataque.
    function test_upgradeCorruptsExistingStorage() public {
        vm.deal(victim, 50 ether);
        vm.prank(victim);
        IVault(address(proxy)).deposit{value: 50 ether}();

        assertEq(IVault(address(proxy)).balances(victim), 50 ether);
        assertEq(IVault(address(proxy)).totalDeposits(), 50 ether);

        VaultLogicV2 v2 = new VaultLogicV2();
        proxy.upgradeTo(address(v2));

        assertEq(address(proxy).balance, 50 ether); // el dinero sigue aqui...
        assertEq(VaultLogicV2(address(proxy)).totalDeposits(), 0); // ...pero la contabilidad dice 0
        assertEq(VaultLogicV2(address(proxy)).balances(victim), 0); // el balance de victim, invisible

        vm.prank(victim);
        vm.expectRevert(bytes("Insufficient balance"));
        VaultLogicV2(address(proxy)).withdraw(1 wei);

        vm.deal(attacker, 1 ether);
        vm.startPrank(attacker);
        VaultLogicV2(address(proxy)).deposit{value: 1 ether}();
        assertEq(VaultLogicV2(address(proxy)).balances(attacker), 1 ether);
        VaultLogicV2(address(proxy)).withdraw(1 ether); // funciona con normalidad
        vm.stopPrank();
    }

    /// @dev Mismo upgrade, pero a VaultLogicV2Fixed: totalDeposits sigue en
    ///      el slot 0 y balances en el slot 1 -- exactamente igual que V1 --
    ///      así que el depósito previo de victim se sigue leyendo
    ///      correctamente tras el upgrade, y puede retirarlo con normalidad.
    function test_mitigation_preservesStorageOnUpgrade() public {
        vm.deal(victim, 50 ether);
        vm.prank(victim);
        IVault(address(proxyFixed)).deposit{value: 50 ether}();

        VaultLogicV2Fixed v2Fixed = new VaultLogicV2Fixed();
        proxyFixed.upgradeTo(address(v2Fixed));

        assertEq(
            VaultLogicV2Fixed(address(proxyFixed)).totalDeposits(), 50 ether, "la contabilidad sobrevive al upgrade"
        );
        assertEq(
            VaultLogicV2Fixed(address(proxyFixed)).balances(victim), 50 ether, "el balance de victim sigue visible"
        );

        vm.prank(victim);
        VaultLogicV2Fixed(address(proxyFixed)).withdraw(50 ether);
        assertEq(victim.balance, 50 ether, "victim recupera su deposito completo, incluso tras el upgrade");
    }
}
