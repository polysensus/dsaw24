// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TugAWar} from "../src/TugAWar.sol";

contract TugAWarTest is Test {
    TugAWar public tao;

    function setUp() public {
        tao = new TugAWar();
    }

    function test_joinLight() public {
      tao.joinTheLight();
    }

    function test_joinDark() public {
      tao.joinTheDark();
    }

    function test_joinLightTwiceReverts() public {
      tao.joinTheLight();
      vm.expectRevert();
      tao.joinTheLight();
    }

    function test_joinBothSidesRevertsLightDark() public {
      tao.joinTheLight();
      vm.expectRevert();
      tao.joinTheDark();
    }

    function test_joinBothSidesRevertsDarkLight() public {
      tao.joinTheDark();
      vm.expectRevert();
      tao.joinTheLight();
    }

    function test_joinDarkTwiceReverts() public {
      tao.joinTheDark();
      vm.expectRevert();
      tao.joinTheDark();
    }

}
