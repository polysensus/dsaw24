// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {TugAWar} from "src/TugAWar.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";

import {TUGAWAR, LIGHT_ACCOUNT} from "./constants.sol";

contract JoinTheLightScript is Script {

    TugAWar public taw;
    function run() external {
        taw = TugAWar(TUGAWAR);

        bytes memory joinTheLightCall = abi.encodeWithSignature("joinTheLight()");
        ERC6551Account lightPlayerAccount = ERC6551Account(payable(LIGHT_ACCOUNT));

        uint256 polyZoneKey = vm.envUint("POLYZONE_KEY");
        vm.startBroadcast(polyZoneKey);
        lightPlayerAccount.execute(payable(address(taw)), 0, joinTheLightCall, 0);
        vm.stopBroadcast();
    }
}
