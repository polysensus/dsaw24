// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// --- test framework imports
import {Test, console} from "forge-std/Test.sol";
import "forge-std/console2.sol";

// --- upstream contract imports
import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

import {GameResult, TugAWar} from "src/TugAWar.sol";

// -- implementation imports
import {ERC6551Account} from "src/ERC6551Account.sol";

contract Demo1Test is Test {
    ERC6551Account public accountImplementation;
    IERC6551Registry public registry;

    address DOWNSTREAM_ZONE = address(0x7eb295761919f3B55378224F75De9b3CB4081f2f);

    TugAWar taw;

    address tawDeployer;
    address accountDeployer;

    // going to set this up for sportsbeard zone 3
    address lightPlayer = address(0x402462EefC217bf2cf4E6814395E1b61EA4c43F7);
    address lightPlayerAccountAddress;
    ERC6551Account lightPlayerAccount;

    address lightPlayer2 = address(0xb675fb3256d475611C33827b2CFD6b04e9550775);

    // 

    address darkPlayer = address(0x8fe19020100e15F7cBa5ACA32454FeCAD4F1aFE3);
    // this is me @robin0f7
    address darkPlayerAccountAddress;
    ERC6551Account darkPlayerAccount;

    address eve;

    uint256 lightZoneTokenId = 3; // TODO: mint a zone with a new wallet for zone 3
    uint256 darkZoneTokenId = 6;

    string RPC = vm.rpcUrl("garnet");
    uint256 expectChainId = 17069;
    uint256 FORK_BLOCK = vm.envOr("FORK_BLOCK", uint256(587129));

    // vm.envOr("6551_REGISTRY_ADDRESS", address(0));
    address EIP6551_REGISTRY = address(0x000000006551c19487814612e58FE06813775758);
    uint256 fork;

    function setUp() public {
        if (!vm.envOr("ENABLE_FORK_TESTS", false)) return;

        fork = vm.createFork(RPC, FORK_BLOCK);
        vm.selectFork(fork);

        tawDeployer = vm.addr(1);
        accountDeployer = vm.addr(2);
        eve = vm.addr(13);


        // The deployer of the implementation can be anything we like
        vm.prank(accountDeployer, accountDeployer);
        accountImplementation = new ERC6551Account();
        registry = IERC6551Registry(EIP6551_REGISTRY);

        // The deployer of the game can be anything we like
        vm.prank(tawDeployer, tawDeployer);
        taw = new TugAWar(DOWNSTREAM_ZONE, address(accountImplementation));

        // Create the accounts.
      
        // Note we deploy the accounts with any wallet we like, only the token holder can use
        // the accounts once deployed.
        vm.prank(accountDeployer, accountDeployer);

        // Create the light player token bound account. The address is
        // counterfactually bound to the walllet. we don't have to deploy the
        // account first (or ever)
        lightPlayerAccountAddress = registry.createAccount(
          address(accountImplementation), 0 /*salt*/, block.chainid,
          address(DOWNSTREAM_ZONE), lightZoneTokenId);

        lightPlayerAccount = ERC6551Account(payable(lightPlayerAccountAddress));

        // The account is the player, it is bound to a token, we don't need another account for lightPlayer2


        // Create the dark player token bound account
        darkPlayerAccountAddress = registry.createAccount(
          address(accountImplementation), 0 /*salt*/, block.chainid,
          address(DOWNSTREAM_ZONE), darkZoneTokenId);

        darkPlayerAccount = ERC6551Account(payable(darkPlayerAccountAddress));

        console.log("lightPlayerAccount", lightPlayerAccountAddress);
        console.log("darkPlayerAccount", darkPlayerAccountAddress);


    }

    function test_expectedForkChainId() public {
        vm.skip(!vm.envOr("ENABLE_FORK_TESTS", false));
        assertEq(vm.activeFork(), fork);
        assertEq(block.chainid, expectChainId);
    }

    function test_joinTheDark() public {
        vm.skip(!vm.envOr("ENABLE_FORK_TESTS", false));
        assertEq(vm.activeFork(), fork);

        // At this point the account holder, who _also_ holds the zone token,
        // can issue transactions using this on chain wallet
        bytes memory joinTheDarkCall = abi.encodeWithSignature("joinTheDark()");
        vm.prank(darkPlayer);
        darkPlayerAccount.execute(payable(address(taw)), 0, joinTheDarkCall, 0);

        // show we can't join twice
        vm.prank(darkPlayer);
        vm.expectRevert();
        darkPlayerAccount.execute(payable(address(taw)), 0, joinTheDarkCall, 0);

        assertEq(taw.isGameRunning(), false);
    }

    function test_joinTheLight() public {
        vm.skip(!vm.envOr("ENABLE_FORK_TESTS", false));
        assertEq(vm.activeFork(), fork);

        // At this point the account holder, who _also_ holds the zone token,
        // can issue transactions using this on chain wallet
        bytes memory joinTheLightCall = abi.encodeWithSignature("joinTheLight()");
        vm.prank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, joinTheLightCall, 0);

        // show we can't join twice
        vm.prank(lightPlayer);
        vm.expectRevert();
        lightPlayerAccount.execute(payable(address(taw)), 0, joinTheLightCall, 0);

        assertEq(taw.isGameRunning(), false);
    }

    function test_isRunning() public {
        vm.skip(!vm.envOr("ENABLE_FORK_TESTS", false));
        assertEq(vm.activeFork(), fork);

        assertEq(taw.isGameRunning(), false);

        // needs both joined to be started
        bytes memory joinTheDarkCall = abi.encodeWithSignature("joinTheDark()");
        vm.prank(darkPlayer);
        darkPlayerAccount.execute(payable(address(taw)), 0, joinTheDarkCall, 0);

        assertEq(taw.isGameRunning(), false);

        bytes memory joinTheLightCall = abi.encodeWithSignature("joinTheLight()");
        vm.prank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, joinTheLightCall, 0);

        assertEq(taw.isGameRunning(), true);
    }

    function test_lightCanAdd() public {
        vm.skip(!vm.envOr("ENABLE_FORK_TESTS", false));
        assertEq(vm.activeFork(), fork);

        // needs both joined to be started
        bytes memory joinTheDarkCall = abi.encodeWithSignature("joinTheDark()");
        vm.prank(darkPlayer);
        darkPlayerAccount.execute(payable(address(taw)), 0, joinTheDarkCall, 0);

        bytes memory joinTheLightCall = abi.encodeWithSignature("joinTheLight()");
        vm.prank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, joinTheLightCall, 0);

        assertEq(taw.isGameRunning(), true);

        bytes memory addCall = abi.encodeWithSignature("Add()");
        vm.prank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
    }

    function test_getCurrentMarker() public {
        vm.skip(!vm.envOr("ENABLE_FORK_TESTS", false));
        assertEq(vm.activeFork(), fork);

        // needs both joined to be started
        bytes memory joinTheDarkCall = abi.encodeWithSignature("joinTheDark()");
        vm.prank(darkPlayer);
        darkPlayerAccount.execute(payable(address(taw)), 0, joinTheDarkCall, 0);

        bytes memory joinTheLightCall = abi.encodeWithSignature("joinTheLight()");
        vm.prank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, joinTheLightCall, 0);

        assertEq(taw.isGameRunning(), true);

        bytes memory addCall = abi.encodeWithSignature("Add()");
        vm.prank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);

        assertEq(taw.getCurrentRopePosition(), 11);
    }


    function test_lightCantSub() public {
        vm.skip(!vm.envOr("ENABLE_FORK_TESTS", false));
        assertEq(vm.activeFork(), fork);

        // needs both joined to be started
        bytes memory joinTheDarkCall = abi.encodeWithSignature("joinTheDark()");
        vm.prank(darkPlayer);
        darkPlayerAccount.execute(payable(address(taw)), 0, joinTheDarkCall, 0);


        bytes memory joinTheLightCall = abi.encodeWithSignature("joinTheLight()");
        vm.prank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, joinTheLightCall, 0);

        bytes memory subCall = abi.encodeWithSignature("Sub()");
        vm.prank(lightPlayer);
        vm.expectRevert();
        lightPlayerAccount.execute(payable(address(taw)), 0, subCall, 0);
    }

    function test_darkCanSub() public {
        vm.skip(!vm.envOr("ENABLE_FORK_TESTS", false));
        assertEq(vm.activeFork(), fork);

        // needs both joined to be started
        bytes memory joinTheDarkCall = abi.encodeWithSignature("joinTheDark()");
        vm.prank(darkPlayer);
        darkPlayerAccount.execute(payable(address(taw)), 0, joinTheDarkCall, 0);

        bytes memory joinTheLightCall = abi.encodeWithSignature("joinTheLight()");
        vm.prank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, joinTheLightCall, 0);

        bytes memory subCall = abi.encodeWithSignature("Sub()");
        vm.prank(darkPlayer);
        darkPlayerAccount.execute(payable(address(taw)), 0, subCall, 0);
    }

    function test_darkCantAdd() public {
        vm.skip(!vm.envOr("ENABLE_FORK_TESTS", false));
        assertEq(vm.activeFork(), fork);

        // needs both joined to be started
        bytes memory joinTheDarkCall = abi.encodeWithSignature("joinTheDark()");
        vm.prank(darkPlayer);
        darkPlayerAccount.execute(payable(address(taw)), 0, joinTheDarkCall, 0);

        bytes memory joinTheLightCall = abi.encodeWithSignature("joinTheLight()");
        vm.prank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, joinTheLightCall, 0);

        bytes memory addCall = abi.encodeWithSignature("Add()");
        vm.prank(darkPlayer);
        vm.expectRevert();
        darkPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
    }

    function test_lightWinsAfter5() public {
        vm.skip(!vm.envOr("ENABLE_FORK_TESTS", false));
        assertEq(vm.activeFork(), fork);

        // needs both joined to be started
        bytes memory joinTheDarkCall = abi.encodeWithSignature("joinTheDark()");
        vm.prank(darkPlayer);
        darkPlayerAccount.execute(payable(address(taw)), 0, joinTheDarkCall, 0);

        bytes memory joinTheLightCall = abi.encodeWithSignature("joinTheLight()");
        vm.prank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, joinTheLightCall, 0);

        bytes memory addCall = abi.encodeWithSignature("Add()");

        vm.startPrank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
        // rope at 11

        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
        // rope at 12

        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
        // rope at 13
        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
        // rope at 14
        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
        // light player wins, check the result exists
        GameResult memory r = taw.getResult(1);
        assertEq(r.winner, lightPlayer);
    }

    function test_light2WinsAfterGettingToken() public {
        vm.skip(!vm.envOr("ENABLE_FORK_TESTS", false));
        assertEq(vm.activeFork(), fork);

        // needs both joined to be started
        bytes memory joinTheDarkCall = abi.encodeWithSignature("joinTheDark()");
        vm.prank(darkPlayer);
        darkPlayerAccount.execute(payable(address(taw)), 0, joinTheDarkCall, 0);

        bytes memory joinTheLightCall = abi.encodeWithSignature("joinTheLight()");
        vm.prank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, joinTheLightCall, 0);

        console.log("JOINED and STARTED");
        console.log(taw.isGameRunning());

        bytes memory addCall = abi.encodeWithSignature("Add()");

        console.log(taw.getCurrentRopePosition());

        vm.startPrank(lightPlayer);
        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
        // rope at 11
        console.log(taw.getCurrentRopePosition());
        console.log("ADDED FIRST");

        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
        // rope at 12
        console.log(taw.getCurrentRopePosition());
        //
  
        console.log("doing transfer");
        // light player 1 gets tired and hands the rope to light player 2
        //
        // **********************************************
        // NOTE: THIS TRANSFERS DOWNSTREAM ZONE OWNERSHIP
        // For the demo we will use metamask or command line thing
        // **********************************************
        IERC721 zoneToken = IERC721(DOWNSTREAM_ZONE);
        zoneToken.safeTransferFrom(
          lightPlayer, lightPlayer2, lightZoneTokenId);

        // show that the original player wallet can no longer pull on the rope
        console.log("confirming authority changed");

        vm.expectRevert();
        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);

        vm.stopPrank();

        console.log("switching to player2");
        console.log(lightPlayer2);
        vm.startPrank(lightPlayer2);

        // same account, a different signer
        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
        // rope at 13
        console.log(taw.getCurrentRopePosition());

        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
        // rope at 14
        console.log(taw.getCurrentRopePosition());
        
        lightPlayerAccount.execute(payable(address(taw)), 0, addCall, 0);
        // light player 2 wins, check the result exists
        console.log(taw.getCurrentRopePosition());
        
        GameResult memory r = taw.getResult(1);
        assertEq(r.winner, lightPlayer2);
    }
}
