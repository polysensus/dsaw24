// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {TugAWar} from "src/TugAWar.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";

import {TUGAWAR, DARK_ACCOUNT} from "./constants.sol";

contract JoinTheDarkScript is Script {

    TugAWar public taw;
    function run() external {
        taw = TugAWar(TUGAWAR);

        bytes memory joinTheDarkCall = abi.encodeWithSignature("joinTheDark()");
        ERC6551Account darkPlayerAccount = ERC6551Account(payable(DARK_ACCOUNT));

        uint256 darkZoneKey = vm.envUint("DARKZONE_KEY");
        vm.startBroadcast(darkZoneKey);
        darkPlayerAccount.execute(payable(address(taw)), 0, joinTheDarkCall, 0);
        vm.stopBroadcast();
    }
}
