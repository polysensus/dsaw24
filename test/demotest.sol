pragma solidity ^0.8.20;

// --- test framework imports
import {Test, console} from "forge-std/Test.sol";
import {FORK_BLOCK} from "scripts/constants.sol";

contract DemoScriptTest is Test {

    string RPC = vm.rpcUrl("garnet");
    uint256 fork;
    uint256 polyZoneKey;
    uint256 dailyZoneKey;
    uint256 darkZoneKey;

    function setUpx() public {
        if (!vm.envOr("ENABLE_FORK_TESTS", false)) return;

        fork = vm.createFork(RPC, FORK_BLOCK);
        vm.selectFork(fork);

        polyZoneKey = vm.envUint("POLYZONE_KEY");
        dailyZoneKey = vm.envUint("DAILYZONE_KEY");
        darkZoneKey = vm.envUint("DARKZONE_KEY");
    }
}
