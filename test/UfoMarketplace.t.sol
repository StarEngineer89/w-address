// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {CommonTestBase} from "./CommonTestBase.t.sol";
import {console} from "forge-std/console.sol";

contract UfoMarketplaceTest is CommonTestBase {
    address internal uapAdminWallet =
        0xbCD418c12CD9910DD5B33b1F8eE47eCc562732fC;
    function setUp() public {
        _commonSetup();
    }

    function test_transferUAPToEscrow() public {
        assertEq(uap.balanceOf(uapAdminWallet), 294000000000000000000000000000);
        
        vm.deal(uapAdminWallet, 1000000 ether);
        vm.startPrank(uapAdminWallet);
        //transfer UAP to Escrow
        uap.transfer(address(escrow), 10000 * 1e18);
        vm.stopPrank();

        // vm.prank(user1);
        // ufoMarketplace.transferUAP(user1, 100 * 1e18);
        // assertEq(uap.balanceOf(user1), 100 * 1e18);        
    }
}
