pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

import {TUGAWAR, DOWNSTREAM_ZONE, POLY_ACCOUNT, DAILY_ACCOUNT, LIGHT_ZONE_TOKEN_ID} from "./constants.sol";

// Transfers the polysensus zone token to Daily Thompson
contract ZoneTransferScript is Script {

    function run() external {
        uint256 zoneKey = vm.envUint("POLYZONE_KEY");
        vm.startBroadcast(zoneKey);

        // We just interact with downstream like any other token
        IERC721 zoneToken = IERC721(DOWNSTREAM_ZONE);

        // **********************************************
        // NOTE: THIS TRANSFERS DOWNSTREAM ZONE OWNERSHIP
        // For the demo we will use metamask or command line thing
        // **********************************************

        zoneToken.safeTransferFrom(
          POLY_ACCOUNT, DAILY_ACCOUNT, LIGHT_ZONE_TOKEN_ID);
    }
}
