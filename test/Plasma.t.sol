// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {CommonTestBase} from "./CommonTestBase.t.sol";
import {console} from "forge-std/console.sol";
import {OnlyWhiteListedCanTransfer} from "../src/UFO/Plasma.sol";

contract PlasmaTest is CommonTestBase {
    function setUp() public {
        _commonSetup();
    }

    function mintPlasmaToUsers() internal {
        address[] memory minters = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        minters[0] = user1;
        amounts[0] = 3000 ether;
        minters[1] = user2;
        amounts[1] = 2000 ether;
        vm.prank(admin);
        plasma.mint(minters, amounts);
    }

    function test_nonTransferability() public {
        mintPlasmaToUsers();

        //user1 isn't whitelisted so it cannot transfer token to others
        vm.startPrank(user1);
        plasma.approve(address(this), 1 ether);
        vm.expectRevert(OnlyWhiteListedCanTransfer.selector);
        plasma.transfer(user2, 1 ether);
        vm.stopPrank();

        //let's whitelist user1
        vm.prank(admin);
        plasma.configWhitelistUser(user1, true);

        vm.startPrank(user1);
        plasma.approve(address(this), 1 ether);
        plasma.transfer(user2, 1 ether);
        vm.stopPrank();
    }

    function test_transferability() public {
        mintPlasmaToUsers();

        vm.prank(admin);
        plasma.configreNonTransferability(false);

        vm.startPrank(user1);
        plasma.approve(address(this), 1 ether);
        plasma.transfer(user3, 1 ether);
        vm.stopPrank();

        vm.prank(admin);
        plasma.configreNonTransferability(true);

        vm.startPrank(user1);
        plasma.approve(address(this), 1 ether);
        vm.expectRevert(OnlyWhiteListedCanTransfer.selector);
        plasma.transfer(user3, 1 ether);
        vm.stopPrank();
    }
}
