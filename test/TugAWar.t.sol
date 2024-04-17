// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TugAWar} from "../src/TugAWar.sol";

contract TugAWarTest is Test {
    TugAWar public tao;

    function setUp() public {
        tao = new TugAWar(address(0), address(0));
    }

    // Moved to Demo1.fokr.t.sol
}
