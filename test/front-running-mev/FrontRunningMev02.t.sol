// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {Pool} from "../../src/front-running-mev/target/Pool.sol";
import {NaiveSwapper} from "../../src/front-running-mev/target/NaiveSwapper.sol";
import {SandwichAttacker} from "../../src/front-running-mev/target/SandwichAttacker.sol";
import {NaiveSwapperFixed} from "../../src/front-running-mev/mitigations/NaiveSwapperFixed.sol";

contract FrontRunningMev02Test is Test {
    MockERC20 token;
    Pool pool;
    NaiveSwapper naiveSwapper;
    SandwichAttacker sandwich;

    NaiveSwapperFixed naiveSwapperFixed;

    address attacker = makeAddr("attacker");
    address victim = makeAddr("victim");

    function setUp() public {
        token = new MockERC20("TOKEN", "TOK");
        pool = new Pool(address(token));

        token.mint(address(this), 1_000_000 ether);
        token.approve(address(pool), 1_000_000 ether);
        vm.deal(address(this), 100 ether);
        pool.addLiquidity{value: 100 ether}(1_000_000 ether);

        naiveSwapper = new NaiveSwapper(address(pool));
        naiveSwapperFixed = new NaiveSwapperFixed(address(pool));

        vm.prank(attacker);
        sandwich = new SandwichAttacker(address(pool), address(token));
    }

    /// @dev Traza exacta (reservas iniciales 100 ETH / 1.000.000 TOKEN):
    ///      frontRun(5 ETH) -> 47.619047619047619047619 TOKEN, reservas
    ///      105/952.380,95. victim.swap(10 ETH) sin proteccion ->
    ///      82.815,73... TOKEN (82.815,73 en vez de los ~90.909,09 que le
    ///      hubieran correspondido sin el sandwich). backRun devuelve los
    ///      47.619... TOKEN -> 5,970654... ETH: beneficio neto ~0,9707 ETH
    ///      sobre 5 ETH puestos (~19%), sin quedarse con ninguna posicion en TOKEN.
    function test_exploit_sandwich() public {
        uint256 balanceBefore = attacker.balance;

        vm.prank(attacker);
        sandwich.frontRun{value: 5 ether}();
        assertEq(sandwich.frontRunTokens(), 47619047619047619047619);

        vm.deal(victim, 10 ether);
        vm.prank(victim);
        naiveSwapper.swap{value: 10 ether}();

        vm.prank(attacker);
        sandwich.backRun();

        assertGt(attacker.balance, balanceBefore, "beneficio neto en ETH");
        assertEq(attacker.balance - balanceBefore, 970654627539503386, "~0.9707 ETH exactos sobre 5 ETH puestos");
        assertEq(token.balanceOf(address(sandwich)), 0, "sin posicion direccional en TOKEN");
    }

    /// @dev Mismo ataque, pero victim usa NaiveSwapperFixed con el
    ///      `expectedOut` justo (90.909,09... TOKEN, el que le correspondería
    ///      sin sandwich) y 1% de slippage máximo. El sandwich desplaza el
    ///      resultado real a ~82.815 TOKEN, muy por debajo de minOut
    ///      (~89.999,99): el swap de victim revierte en vez de ejecutarse a
    ///      un precio mucho peor.
    function test_mitigation_blocksSandwich() public {
        uint256 fairOut = (1_000_000 ether * 10 ether) / (100 ether + 10 ether);
        assertEq(fairOut, 90909090909090909090909);

        vm.prank(attacker);
        sandwich.frontRun{value: 5 ether}();

        vm.deal(victim, 10 ether);
        vm.prank(victim);
        vm.expectRevert(bytes("Slippage exceeded"));
        naiveSwapperFixed.swap{value: 10 ether}(fairOut);
    }
}
