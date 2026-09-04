// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {SimpleAMM} from "../../src/oracle-manipulation/target/SimpleAMM.sol";
import {TWAPOracle} from "../../src/oracle-manipulation/target/TWAPOracle.sol";
import {LendingPoolTWAP} from "../../src/oracle-manipulation/target/LendingPoolTWAP.sol";
import {TWAPOracleFixed} from "../../src/oracle-manipulation/mitigations/TWAPOracleFixed.sol";
import {TWAPManipulationAttacker} from "../../src/oracle-manipulation/attacks/TWAPManipulationAttacker.sol";

contract OracleManipulation02Test is Test {
    MockERC20 token;
    SimpleAMM amm;
    TWAPOracle twapOracle;
    LendingPoolTWAP lendingPool;

    TWAPOracleFixed twapOracleFixed;
    LendingPoolTWAP lendingPoolFixed;

    address attackerOwner = makeAddr("attackerOwner");

    function setUp() public {
        token = new MockERC20("TOKEN", "TOK");
        amm = new SimpleAMM(address(token));

        token.mint(address(this), 1_000_000 ether);
        token.approve(address(amm), 1_000_000 ether);
        vm.deal(address(this), 100 ether);
        amm.addLiquidity{value: 100 ether}(1_000_000 ether);

        twapOracle = new TWAPOracle(address(amm));
        lendingPool = new LendingPoolTWAP(address(twapOracle), address(token));
        vm.deal(address(lendingPool), 10 ether);

        twapOracleFixed = new TWAPOracleFixed(address(amm));
        lendingPoolFixed = new LendingPoolTWAP(address(twapOracleFixed), address(token));
        vm.deal(address(lendingPoolFixed), 10 ether);
    }

    /// @dev Traza exacta: 80 ETH + update() diluyen el precio real a la mitad;
    ///      20 ETH mas + update() lo expulsan del todo (ambas lecturas ya
    ///      manipuladas). maxBorrow con 5.000 TOKEN pasa a ~1.267 ETH -- pedir
    ///      1 ETH cabe. Deshacer ambos swaps devuelve 100 ETH menos 1 wei de
    ///      redondeo. attackerOwner gasta sus 100 ETH iniciales como msg.value
    ///      y recibe de vuelta (100 ETH - 1 wei) + 1 ETH prestado: balance
    ///      final = 101 ETH - 1 wei -- ese ETH de más es el beneficio real.
    function test_exploit_twapManipulation() public {
        vm.startPrank(attackerOwner);
        TWAPManipulationAttacker attacker = new TWAPManipulationAttacker(
            address(amm), address(twapOracle), address(lendingPool), address(token)
        );
        vm.stopPrank();

        token.mint(address(attacker), 5000 ether);
        vm.startPrank(address(attacker));
        token.approve(address(lendingPool), 5000 ether);
        lendingPool.depositCollateral(5000 ether);
        vm.stopPrank();

        vm.deal(attackerOwner, 100 ether);
        vm.prank(attackerOwner);
        attacker.attack{value: 100 ether}(1 ether);

        assertEq(attackerOwner.balance, 100999999999999999999, "balance final: 0 tras gastar 100 ETH, +101 ETH menos 1 wei de redondeo (dos swaps)");
    }

    /// @dev Mismo ataque contra TWAPOracleFixed: la segunda llamada a
    ///      update(), en el mismo timestamp que la primera, revierte por
    ///      "Too soon" -- toda la transaccion del atacante revierte con ella.
    function test_mitigation_blocksTwapManipulation() public {
        vm.startPrank(attackerOwner);
        TWAPManipulationAttacker attackerFixed = new TWAPManipulationAttacker(
            address(amm), address(twapOracleFixed), address(lendingPoolFixed), address(token)
        );
        vm.stopPrank();

        token.mint(address(attackerFixed), 5000 ether);
        vm.startPrank(address(attackerFixed));
        token.approve(address(lendingPoolFixed), 5000 ether);
        lendingPoolFixed.depositCollateral(5000 ether);
        vm.stopPrank();

        vm.deal(attackerOwner, 100 ether);
        vm.prank(attackerOwner);
        vm.expectRevert(bytes("Too soon"));
        attackerFixed.attack{value: 100 ether}(1 ether);
    }
}
