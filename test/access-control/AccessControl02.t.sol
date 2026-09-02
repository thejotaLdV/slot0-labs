// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Wallet} from "../../src/access-control/target/Wallet.sol";
import {WalletFixed} from "../../src/access-control/mitigations/WalletFixed.sol";
import {Phish} from "../../src/access-control/attacks/Phish.sol";

contract AccessControl02Test is Test {
    Wallet wallet;
    WalletFixed walletFixed;

    address owner = makeAddr("owner");
    address attacker = makeAddr("attacker");

    function setUp() public {
        wallet = new Wallet(owner);
        walletFixed = new WalletFixed(owner);

        vm.deal(owner, 2 ether);
        vm.prank(owner);
        wallet.deposit{value: 2 ether}();

        vm.deal(owner, 2 ether);
        vm.prank(owner);
        walletFixed.deposit{value: 2 ether}();
    }

    /// @dev La víctima (owner) es engañada para llamar directamente a
    ///      Phish.claimReward() -- msg.sender Y tx.origin de esa llamada son
    ///      `owner`. Dentro, Phish llama a wallet.transfer(): el msg.sender
    ///      que ve Wallet ahora es Phish, pero tx.origin sigue siendo owner.
    function test_exploit_txOriginPhishing() public {
        Phish phish = new Phish(address(wallet), payable(attacker));

        vm.prank(owner, owner);
        phish.claimReward();

        assertEq(address(wallet).balance, 0);
        assertEq(attacker.balance, 2 ether);
    }

    function test_mitigation_blocksTxOriginPhishing() public {
        Phish phishFixed = new Phish(address(walletFixed), payable(attacker));

        vm.prank(owner, owner);
        vm.expectRevert(bytes("Not owner"));
        phishFixed.claimReward();

        assertEq(address(walletFixed).balance, 2 ether, "el balance no debe moverse");
        assertEq(attacker.balance, 0);
    }
}
