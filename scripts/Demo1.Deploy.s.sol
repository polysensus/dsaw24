// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {TugAWar} from "src/TugAWar.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";

contract DeployScript is Script {

    TugAWar public taw;
    ERC6551Account public accountImplementation;

    address public lightPlayerAccountAddress;
    address public darkPlayerAccountAddress;

    function run() external {
      // This deploys a new diamond. Which means its state is completely fresh
      //
      // XXX: this has some issues with transaction order dependence

        uint256 deployKey = vm.envUint("DEPLOY_KEY");

        console.log("START DEPLOY");
        vm.startBroadcast(deployKey);

        // already deployed on garnet above 587129
        address EIP6551_REGISTRY = address(0x000000006551c19487814612e58FE06813775758);
        address DOWNSTREAM_ZONE = address(0x7eb295761919f3B55378224F75De9b3CB4081f2f);

        IERC6551Registry registry = IERC6551Registry(EIP6551_REGISTRY);

        console.log("DEPLOYING ACCOUNT IMPLEMENTATION");
        accountImplementation = new ERC6551Account();
        console.log(address(accountImplementation));
        taw = new TugAWar(DOWNSTREAM_ZONE, address(accountImplementation));

        // We can just go ahead and counter factually deploy all the token
        // bound accounts. It just so happens the tokens had already been
        // minted but the don't need to be. The accounts are forever bound to a
        // specific id whether or not it has been minted yet.

        address polyZoneOwner = vm.envOr("POLYZONE_OWNER", address(0xb675fb3256d475611C33827b2CFD6b04e9550775));
        uint256 polyZoneId = 11;  // initial owner 0xb675fb3256d475611C33827b2CFD6b04e9550775
        address dailyZoneOwner = vm.envOr("DAILYZONE_OWNER", address(0x0b7EB5B657fE3388623C32677Fbc26a14edc53D9));

        uint256 darkZoneTokenId = 6;
        address darkZoneOwner = address(0x8fe19020100e15F7cBa5ACA32454FeCAD4F1aFE3);

        // LIGHT SIDE ACCOUNT. 
        console.log("DEPLOYING LIGHT ACCOUNT");

        // Create the light player token bound account. The address is
        // counterfactually bound to the holder of polyZoneId. We don't have to deploy the
        // account first (or ever)
        lightPlayerAccountAddress = registry.createAccount(
          address(accountImplementation), 0 /*salt*/, block.chainid,
          address(DOWNSTREAM_ZONE), polyZoneId);
        console.log("lightPlayerAccount", lightPlayerAccountAddress);

        // DARK SIDE ACCOUNT
        console.log("DEPLOYING DARK ACCOUNT");

        darkPlayerAccountAddress = registry.createAccount(
          address(accountImplementation), 0 /*salt*/, block.chainid,
          address(DOWNSTREAM_ZONE), darkZoneTokenId);
        console.log("darkPlayerAccount", darkPlayerAccountAddress);

        // We can just create the accounts with *any* key, only the token holder can use them
        vm.stopBroadcast();
    }
}
