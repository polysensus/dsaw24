// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// --- test framework imports
import {Test, console} from "forge-std/Test.sol";
import "forge-std/console2.sol";

import {ERC6551Account} from "src/ERC6551Account.sol";

import {DeployScript} from "scripts/Demo1.Deploy.s.sol";
import {console} from "forge-std/Test.sol";

// --- upstream contract imports
//

contract DeployTest is Test {

    string RPC = vm.rpcUrl("garnet");
    uint256 FORK_BLOCK = vm.envOr("FORK_BLOCK", uint256(604068));
    uint256 fork;

    uint256 polyZoneKey;
    uint256 dailyZoneKey;
    uint256 darkZoneKey;

  function setUp() public {
      if (!vm.envOr("ENABLE_FORK_TESTS", false)) return;

      fork = vm.createFork(RPC, FORK_BLOCK);
      vm.selectFork(fork);
      uint256 polyZoneKey = vm.envUint("POLYZONE_KEY");
      uint256 dailyZoneKey = vm.envUint("DAILYZONE_KEY");
      uint256 darkZoneKey = vm.envUint("DARKZONE_KEY");
  }

  function test_deploy() public {
    if (!vm.envOr("ENABLE_FORK_TESTS", false)) return;
    assertEq(vm.activeFork(), fork);
    vm.selectFork(fork);

    DeployScript s = new DeployScript();

    s.run();

    assertEq(s.taw().isGameRunning(), false);
    assertEq(s.taw().getCurrentRopePosition(), 10);

    // just check we can use the light account
    //
    uint256 polyZoneKey = vm.envUint("POLYZONE_KEY");
    uint256 dailyZoneKey = vm.envUint("DAILYZONE_KEY");
    uint256 darkZoneKey = vm.envUint("DARKZONE_KEY");

    address polyZoneOwner = vm.envOr("POLYZONE_OWNER", address(0xb675fb3256d475611C33827b2CFD6b04e9550775));
    address darkZoneOwner = address(0x8fe19020100e15F7cBa5ACA32454FeCAD4F1aFE3);

    bytes memory joinTheLightCall = abi.encodeWithSignature("joinTheLight()");
    address aa = s.lightPlayerAccountAddress();
    console.log("xxxx");
    console.log(aa);
    console.log("xxxx");
    ERC6551Account lightPlayerAccount = ERC6551Account(payable(s.lightPlayerAccountAddress()));
    vm.startBroadcast(polyZoneKey);
    lightPlayerAccount.execute(payable(address(s.taw())), 0, joinTheLightCall, 0);
    vm.stopBroadcast();

    bytes memory joinTheDarkCall = abi.encodeWithSignature("joinTheDark()");
    ERC6551Account darkPlayerAccount = ERC6551Account(payable(s.darkPlayerAccountAddress()));

    vm.startBroadcast(darkZoneKey);
    darkPlayerAccount.execute(payable(address(s.taw())), 0, joinTheDarkCall, 0);
    vm.stopBroadcast();


    bytes memory addCall = abi.encodeWithSignature("Add()");
    vm.startBroadcast(polyZoneKey);
    lightPlayerAccount.execute(payable(address(s.taw())), 0, addCall, 0);
    assertEq(s.taw().getCurrentRopePosition(), 11);
    vm.stopBroadcast();

    bytes memory subCall = abi.encodeWithSignature("Sub()");
    vm.startBroadcast(darkZoneKey);
    darkPlayerAccount.execute(payable(address(s.taw())), 0, subCall, 0);
    vm.stopBroadcast();
    assertEq(s.taw().getCurrentRopePosition(), 10);
  }
}
