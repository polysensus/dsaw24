// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {TugAWar} from "src/TugAWar.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";

import {TUGAWAR, LIGHT_ACCOUNT} from "./constants.sol";

// Sign the transaction with the polysensus key
// Will fail if the polysensus wallet no longer holds the zone token
contract DailyAddScript is Script {

    TugAWar public taw;
    function run() external {
        taw = TugAWar(TUGAWAR);

        // Pull to the light ...

        bytes memory addCall = abi.encodeWithSignature("Add()");
        ERC6551Account lightPlayerAccount = ERC6551Account(payable(LIGHT_ACCOUNT));

        // This will fail before the zone token is transfered from the Polysensus Zone
        uint256 dailyZoneKey = vm.envUint("DAILYZONE_KEY");
        vm.startBroadcast(dailyZoneKey);
        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
        vm.stopBroadcast();
    }
}
