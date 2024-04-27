// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// --- test framework imports
import {Test, console} from "forge-std/Test.sol";
import "forge-std/console2.sol";

import {ERC6551Account} from "src/ERC6551Account.sol";

import {DeployScript} from "scripts/Demo1.Deploy.s.sol";
import {console} from "forge-std/Test.sol";

import {FORK_BLOCK} from "scripts/constants.sol";
import {DemoScriptTest} from "./demotest.sol";
import {JoinTheLightScript} from "scripts/jointhelight.s.sol";

contract JoinTheLightTest is DemoScriptTest {
    function setUp() public {
        if (!vm.envOr("ENABLE_FORK_TESTS", false)) return;

        fork = vm.createFork(RPC, FORK_BLOCK);
        vm.selectFork(fork);
    }

    function test_joinTheLightScript() public{
      JoinTheLightScript s = new JoinTheLightScript();
      s.run();
    }
}

