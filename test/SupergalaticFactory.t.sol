// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {CommonTestBase} from "./CommonTestBase.t.sol";
import {console} from "forge-std/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract SuperGalaticFactoryTest is CommonTestBase {
    function setUp() public {
        _commonSetup();
    }

    function test_MintNftByNative() public {
        uint256 currentMintCount = 2997;
        vm.startPrank(admin);
        superGalaticFactory.setPhase(1);
        superGalaticFactory.addUpdatePriceRole(admin);
        superGalaticFactory.updateBeamPriceOfNft(1e18);
        superGalaticFactory.updateAlreadyMintedGenesisNft(currentMintCount);
        vm.stopPrank();
        // uint256 beamPriceInUSDT = superGalaticFactory.getbeamPrice();
        //one NFT price is 250$
        uint256 nftcount = 10;
        //beamAmountPerNft is beam amount of 1 USDT
        uint256 nftPriceInBeamWei = superGalaticFactory.beamAmountPerNft() *
            250 *
            (3000 - currentMintCount) +
            superGalaticFactory.beamAmountPerNft() *
            275 *
            (nftcount - (3000 - currentMintCount));
        vm.startPrank(user1);
        uint256[] memory categoryIds = new uint256[](1);
        categoryIds[0] = 0;

        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = nftcount;

        bytes32[] memory proof = new bytes32[](1);
        //proof[0] = 2;

        vm.roll(50);
        superGalaticFactory.registerForMint();
        vm.roll(100);
        console.log("total beam price", nftPriceInBeamWei);
        superGalaticFactory.mintWithBeam{value: nftPriceInBeamWei}(
            categoryIds,
            nftAmounts,
            proof
        );
        vm.stopPrank();

        console.log(
            "nft count",
            IERC721Upgradeable(superGalaticFactory.nftContracts(categoryIds[0]))
                .balanceOf(user1)
        );

        console.log(
            "minted nft count",
            superGalaticFactory.alreadyMintedGenesisNFT()
        );
    }

    function test_MintNftByUSDT() public {
        uint256 currentMintCount = 2997;
        vm.startPrank(admin);
        superGalaticFactory.setPhase(1);
        superGalaticFactory.addUpdatePriceRole(admin);
        superGalaticFactory.updateAlreadyMintedGenesisNft(currentMintCount);
        vm.stopPrank();
        // uint256 beamPriceInUSDT = superGalaticFactory.getbeamPrice();
        //one NFT price is 250$
        uint256 nftcount = 10;
        //beamAmountPerNft is beam amount of 1 USDT
        uint256 nftPriceInUSDT = 250 *
            (3000 - currentMintCount) +
            275 *
            (nftcount - (3000 - currentMintCount));

        vm.startPrank(user1);
        uint256[] memory categoryIds = new uint256[](1);
        categoryIds[0] = 0;

        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = nftcount;

        bytes32[] memory proof = new bytes32[](1);
        //proof[0] = 2;

        vm.roll(50);
        superGalaticFactory.registerForMint();
        vm.roll(100);
        
        USDT.approve(address(superGalaticFactory), nftPriceInUSDT * 1e6);
        superGalaticFactory.mintWithUSDT(categoryIds, nftAmounts, proof);
        vm.stopPrank();

        console.log(
            "nft count",
            IERC721Upgradeable(superGalaticFactory.nftContracts(categoryIds[0]))
                .balanceOf(user1)
        );

        console.log(
            "minted nft count",
            superGalaticFactory.alreadyMintedGenesisNFT()
        );
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

    function test_mintSuperGalatic() public {
        mintPlasmaToUsers();

        //phase = 0 is presale and in this presale it requires merkle proof logic
        vm.prank(admin);
        superGalaticFactory.setPhase(1);

        bytes32[] memory proof = new bytes32[](1);
        proof[
            0
        ] = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;
        vm.startPrank(user1);
        plasma.approve(address(superGalaticFactory), 1000 ether);
        uint256[] memory categories = new uint256[](1);
        categories[0] = 0;
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        superGalaticFactory.mintBatchSuperGalatic(categories, ids, proof);
        vm.stopPrank();

        console.log(
            "minted nft count",
            superGalaticFactory.alreadyMintedGenesisNFT()
        );
        assertEq(superGalaticFactory.alreadyMintedGenesisNFT(), 1);
    }

    function test_updateBodyPart() public {
        mintPlasmaToUsers();

        //phase = 0 is presale and in this presale it requires merkle proof logic
        vm.prank(admin);
        superGalaticFactory.setPhase(1);

        bytes32[] memory proof = new bytes32[](1);
        proof[
            0
        ] = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;
        console.log("user1", user1);
        console.log("uap", uap.balanceOf(user1));

        vm.startPrank(user1);
        plasma.approve(address(superGalaticFactory), 1000 ether);
        uap.approve(address(superGalaticFactory), 10000000000 ether);

        uint256[] memory categories = new uint256[](1);
        categories[0] = 0;
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        superGalaticFactory.mintBatchSuperGalatic(categories, ids, proof);

        console.log(
            "nft contract address",
            superGalaticFactory.nftContracts(0)
        );
        superGalaticFactory.updateNFTBodypart(
            superGalaticFactory.nftContracts(0),
            1,
            1
        );
        vm.stopPrank();
    }

    function test_purchaseLootbox() public {
        vm.startPrank(user1);
        console.log("usdt balance", USDT.balanceOf(user1));
        USDT.approve(address(superGalaticFactory), 1000000 * 1e6);
        superGalaticFactory.purchaseLootbox(30, 2);

        superGalaticFactory.purchaseLootboxAndSendGift(20, user2, 2);

        console.log("usdt balance", USDT.balanceOf(user1));
        console.log(
            "purchased lootbox",
            superGalaticFactory.alreadyPurchasedLootBoxCount()
        );
        console.log("wapon price", superGalaticFactory.getWeaponUsdtPrice());
        vm.stopPrank();
    }
}
