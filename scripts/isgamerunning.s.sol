// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {console} from "forge-std/Test.sol";
import {TugAWar} from "src/TugAWar.sol";
import {TUGAWAR} from "./constants.sol";

// Sign the transaction with the polysensus key
// Will fail if the polysensus wallet no longer holds the zone token
contract IsGameRunningScript is Script {

    TugAWar public taw;
    function run() external {
        taw = TugAWar(TUGAWAR);

        bool running = taw.isGameRunning();
        console.log("game running", running);
    }
}
