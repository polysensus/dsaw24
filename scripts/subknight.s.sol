// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {TugAWar} from "src/TugAWar.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";

import {TUGAWAR, DARK_ACCOUNT} from "./constants.sol";

// Sign the transaction with the polysensus key
// Will fail if the polysensus wallet no longer holds the zone token
contract SubKnightScript is Script {

    TugAWar public taw;
    function run() external {
        taw = TugAWar(TUGAWAR);

        // Pull to the light ...

        bytes memory subCall = abi.encodeWithSignature("Sub()");
        ERC6551Account darkPlayerAccount = ERC6551Account(payable(DARK_ACCOUNT));

        // This will fail after the zone token is transfered to Daily Thompson's Zone
        uint256 knightZoneKey = vm.envUint("DARKZONE_KEY");
        vm.startBroadcast(knightZoneKey);
        darkPlayerAccount.execute(payable(address(taw)), 0, subCall, 0);
        vm.stopBroadcast();
    }
}
