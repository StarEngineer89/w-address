// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import {PRBTest} from "prb-test/PRBTest.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {SuperGalaticFactory} from "../src/UFO/SuperGalaticFactory.sol";
import {SuperGalatic} from "../src/UFO/SuperGalatic.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";
import {Beacon} from "../src/UFO/Beacon.sol";
import {Utilities} from "./Utilities.t.sol";
import {Plasma} from "../src/UFO/Plasma.sol";
import {Weapon} from "../src/UFO/Weapon.sol";
import {Escrow} from "../src/Escrow.sol";
import {UAP} from "../src/UAP.sol";
import {UfoMarketplace} from "../src/marketplace/UfoMarketplace.sol";
import {FactoryHelper} from "../src/UFO/FactoryHelper.sol";
import {XToken} from "../src/XToken.sol";
contract CommonTestBase is PRBTest {
    Utilities internal utils;
    uint256 public beamMainnetFork;

    TransparentUpgradeableProxy transparentProxy;
    SuperGalaticFactory internal superGalaticFactory;
    SuperGalatic internal superGalatic;
    Plasma internal plasma;
    UAP internal uap;
    IUniswapV2Pair internal usdtPair;
    Beacon internal beacon;
    Weapon internal weapon;
    Escrow internal escrow;
    UfoMarketplace internal ufoMarketplace;
    FactoryHelper internal factoryHelper;
    XToken internal USDT;
    address payable[] internal users;
    address internal proxyAdmin;
    address internal admin;
    address internal taxWallet;
    address internal WBEAM = 0xD51BFa777609213A653a2CD067c9A0132a2D316A;

    address internal user1;
    address internal user2;
    address internal user3;
    function _commonSetup() internal {
        beamMainnetFork = vm.createFork("https://build.onbeam.com/rpc");
        vm.selectFork(beamMainnetFork);

        utils = new Utilities();
        users = utils.createUsers(10);
        proxyAdmin = users[0];
        admin = users[1];
        taxWallet = users[2];
        user1 = users[3];
        user2 = users[4];
        user3 = users[5];

        vm.deal(user1, 1000000 ether);
        vm.deal(user2, 1000000 ether);
        vm.deal(user3, 1000000 ether);
        USDT = new XToken("USDT", "USDT", 1000000 * 1e6, 6, user1);
        factoryHelper = new FactoryHelper(admin);

        usdtPair = IUniswapV2Pair(0x7063F3446223Bc4f5c37B0F9d1e12547F0358e90);
        superGalatic = new SuperGalatic();
        beacon = new Beacon(admin, address(superGalatic));

        //deploy plasma
        plasma = new Plasma("Plasma", "PLS", admin);

        //deploy uap
        uap = new UAP();
        transparentProxy = new TransparentUpgradeableProxy(
            address(uap),
            proxyAdmin,
            ""
        );
        UAP(address(transparentProxy)).initialize(admin, taxWallet);
        uap = UAP(address(transparentProxy));
        // deploy superGalaticFactory
        superGalaticFactory = new SuperGalaticFactory();
        transparentProxy = new TransparentUpgradeableProxy(
            address(superGalaticFactory),
            proxyAdmin,
            ""
        );

        SuperGalaticFactory(address(transparentProxy)).initialize(
            admin,
            address(beacon),
            address(plasma),
            1000 * 1e18, //1000 Plasma per NFT
            1e17, //0.1 ETH per Weapon
            address(uap),
            address(factoryHelper)
        );
        superGalaticFactory = SuperGalaticFactory(address(transparentProxy));
        
        //deploy weapon
        weapon = new Weapon();
        transparentProxy = new TransparentUpgradeableProxy(
            address(weapon),
            proxyAdmin,
            ""
        );
        Weapon(address(transparentProxy)).initialize(
            admin,
            address(superGalaticFactory)
        );
        weapon = Weapon(address(transparentProxy));

        //marketplace initialization
        ufoMarketplace = new UfoMarketplace();
        transparentProxy = new TransparentUpgradeableProxy(
            address(ufoMarketplace),
            proxyAdmin,
            ""
        );

        ufoMarketplace = UfoMarketplace(address(transparentProxy));
        ufoMarketplace.initialize(admin, 250, address(uap));

        escrow = new Escrow(address(uap), address(ufoMarketplace), admin);
        //update weapon address in superGalaticFactory
        vm.startPrank(admin);
        superGalaticFactory.updateWeaponAddr(address(weapon));
        superGalaticFactory.setMarketplaceAddress(address(ufoMarketplace));
        superGalaticFactory.setTokenAddresses(address(0), address(0), address(USDT), address(0));
        //distribute uap
        uap.setup();

        ufoMarketplace.setUAPEscrowAddress(address(escrow));
        vm.stopPrank();
    }
}
