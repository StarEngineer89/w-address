//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {CommonTestBase} from "./CommonTestBase.t.sol";
import {console} from "forge-std/console.sol";
import {CannotMint} from "../src/UAP.sol";
contract UAP is CommonTestBase {
    function setUp() public {
        _commonSetup();
        //need to disable "if(block.chainid != 1) revert NotAllowedInThisBlockchain();" in uap contract
        uap.setup();
    }

    // function test_mintUAP() public {
    //     console.log("total supply", uap.totalSupply());

    //     vm.prank(admin);
    //     vm.expectRevert(CannotMint.selector);
    //     uap.mint(user3, 1e18);
    // }

    function test_teamAdvisorTokenClaim() public {
        console.log("current balance", uap.balanceOf(uap.adminWallet()));
        assertEq(uap.balanceOf(uap.adminWallet()), 294000000000000000000000000000);

        vm.startPrank(admin);        
        vm.warp(block.timestamp + 7884000);
        uap.claimUnlockedTeamAdvisorTokenAmount();
        console.log("current balance", uap.balanceOf(uap.adminWallet()));
        console.log("already calimed token amount", uap.alreadyClaimedTeamAdvisorTokenAmount());

        vm.warp(block.timestamp + 7884000 * 2);
        uap.claimUnlockedTeamAdvisorTokenAmount();
        console.log("current balance", uap.balanceOf(uap.adminWallet()));
        console.log("already calimed token amount", uap.alreadyClaimedTeamAdvisorTokenAmount());

        vm.warp(block.timestamp + 7884000 * 3);
        uap.claimUnlockedTeamAdvisorTokenAmount();
        console.log("current balance", uap.balanceOf(uap.adminWallet()));
        console.log("already calimed token amount", uap.alreadyClaimedTeamAdvisorTokenAmount());

        vm.warp(block.timestamp + 7884000 * 4);
        uap.claimUnlockedTeamAdvisorTokenAmount();
        console.log("current balance", uap.balanceOf(uap.adminWallet()));
        console.log("already calimed token amount", uap.alreadyClaimedTeamAdvisorTokenAmount());

        vm.warp(block.timestamp + 7884000 * 4 + 100);
        uap.claimUnlockedTeamAdvisorTokenAmount();
        console.log("current balance", uap.balanceOf(uap.adminWallet()));
        console.log("already calimed token amount", uap.alreadyClaimedTeamAdvisorTokenAmount());
        vm.stopPrank();
    }
}
