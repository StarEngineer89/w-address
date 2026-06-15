// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {CommonTestBase} from "./CommonTestBase.t.sol";
import {console} from "forge-std/console.sol";

contract FactoryHelperTest is CommonTestBase{
    function setUp() public {
        _commonSetup();
    }

    function test_factoryHelper() public view {
        console.log("nft cost",  factoryHelper.getNftUAPCost(0,1));
        console.log("weapon cost",  factoryHelper.getWeaponUAPCost(0,1,1));
    }
}