// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";

contract DeployAccountImplementationScript is Script {

  function run() public {
    uint256 deployKey = vm.envUint("DEPLOY_KEY");
    vm.startBroadcast(deployKey);
    runInternal();
    vm.stopBroadcast();
  }
  function runInternal() internal {
    ERC6551Account accountImplementation = new ERC6551Account();
    console.log(address(accountImplementation));
  }
}

