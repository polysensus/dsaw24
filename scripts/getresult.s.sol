// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {console} from "forge-std/Test.sol";
import {GameResult, TugAWar} from "src/TugAWar.sol";
import {TUGAWAR} from "./constants.sol";

contract GetResultScript is Script {

    TugAWar public taw;
    function run() external {
        taw = TugAWar(TUGAWAR);

        // hard coded to the first result
        GameResult memory r =  taw.getResult(2);
        console.log("Game 2 winner", r.winner);
        console.log("Game 2 finalLightHolder", r.finalLightPlayer);
        console.log("Game 2 finalDarkHolder", r.finalDarkPlayer);
    }
}
