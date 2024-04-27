// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// --- test framework imports
import {Test, console} from "forge-std/Test.sol";
import "forge-std/console2.sol";

import {ERC6551Account} from "src/ERC6551Account.sol";

import {CreateZoneTokenBountAccountsScript} from "scripts/CreateZoneTBAs.s.sol";
import {console} from "forge-std/Test.sol";


contract CreateZoneTokenBountAccountsScriptTest is Test {

  string RPC = vm.rpcUrl("rpc");
  uint256 FORK_BLOCK = vm.envUint("FORK_BLOCK");
  uint256 fork;

  function setUp() public {
      if (!vm.envOr("ENABLE_FORK_TESTS", false)) return;

      fork = vm.createFork(RPC, FORK_BLOCK);
      vm.selectFork(fork);
      uint256 polyZoneKey = vm.envUint("POLYZONE_KEY");
      uint256 dailyZoneKey = vm.envUint("DAILYZONE_KEY");
      uint256 darkZoneKey = vm.envUint("DARKZONE_KEY");
  }

  function test_CreateZoneTokenBountAccountsScript() public {
    if (!vm.envOr("ENABLE_FORK_TESTS", false)) return;
    assertEq(vm.activeFork(), fork);
    vm.selectFork(fork);

    CreateZoneTokenBountAccountsScript s = new CreateZoneTokenBountAccountsScript();
    s.run();
  }
}
