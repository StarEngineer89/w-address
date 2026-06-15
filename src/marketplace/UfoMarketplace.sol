//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./../Errors.sol";
import "./../signature/EIP712UfoMarketplace.sol";
import {IEscrow} from "./../Escrow.sol";
/**
 * @notice SuperGalatic NFT Contract
 */
error InvalidSignature();
error AddressNotNull();
error WrongParam();
error ListingIsNotEnabled();
contract UfoMarketplace is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    EIP712UfoMarketplace,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public wethAddr;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public platformFee;
    address public ufoAddress;
    address public usdtAddress;
    address public uapAddress;

    address public revenueWallet; //0xB980D88Ae1e9599096e6030fb5381483E4312f31;
    address public adminWallet; //0xbCD418c12CD9910DD5B33b1F8eE47eCc562732fC;
    address public uapEscrow;
    //signature validataion
    mapping(bytes => bool) public alreadyUsedSignature;
    //enable or disable listing
    bool public isEnableGenesisListing;

    event AuctionSuccessful(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _totalPrice,
        uint256 priceUnit,
        address _winner
    ); //_totalPrice = actual Price + platform fee
    event FixedItemSuccessful(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _totalPrice,
        uint256 priceUnit,
        address _buyer
    );
    event ClaimUAP(address indexed _user, uint256 amount);

    //for weapon nft it used this one event for both of fixed and auction sell by specifying buySellType
    event LootBuySellSuccess(
        uint256 buySellType,
        address sender,
        address receiver,
        uint256 price,
        uint256 priceUnit,
        uint256 weaponId,
        address weaponContract
    );

    event UpdateWrappedNativeAddr(address wNative);
    event UpdateUfoAddr(address ufo);
    event UpdateUsdtAddr(address usdt);
    event SetBackendSigner(address signer);
    event UpdatePlateformFee(uint256 newFee);    
    event UpdateEscrow(address escrow);
    event Withdraw(
        address recipient,
        uint256 native,
        uint256 usdt,
        uint256 ufo
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        uint256 _platformFee,
        address _uap
    ) external initializer {
        if (
            _admin == address(0) ||            
            _uap == address(0)
        ) revert AddressNotNull();
        require(_platformFee <= 10000, Errors.EXCEED_PLATFORM_FEE_VALUE);
        __Ownable_init();
        transferOwnership(_admin);
        __Pausable_init();

        platformFee = _platformFee;
        uapAddress = _uap;
        revenueWallet = 0xB980D88Ae1e9599096e6030fb5381483E4312f31;
        adminWallet = 0xbCD418c12CD9910DD5B33b1F8eE47eCc562732fC;
    }

    function setWETHAddress(address _wethAddr) external onlyOwner {
        if (_wethAddr == address(0)) revert AddressNotNull();
        require(wethAddr != _wethAddr, Errors.SHOULD_NOT_SAME);
        wethAddr = _wethAddr;

        emit UpdateWrappedNativeAddr(_wethAddr);
    }

    function setUfoAddress(address ufoAddr) external onlyOwner {
        if (ufoAddr == address(0)) revert AddressNotNull();
        require(ufoAddress != ufoAddr, Errors.SHOULD_NOT_SAME);
        ufoAddress = ufoAddr;

        emit UpdateUfoAddr(ufoAddr);
    }

    function setUSDTAddress(address usdtAddr) external onlyOwner {
        if (usdtAddr == address(0)) revert AddressNotNull();
        require(usdtAddress != usdtAddr, Errors.SHOULD_NOT_SAME);
        usdtAddress = usdtAddr;

        emit UpdateUsdtAddr(usdtAddr);
    }

    function setUAPEscrowAddress(address escrow) external onlyOwner {
        if (escrow == address(0)) revert AddressNotNull();
        uapEscrow = escrow;

        emit UpdateEscrow(escrow);
    }

    /// @dev update the platform's fee
    /// @param newFee - new fee value to be changed
    function updatePlateformFee(uint256 newFee) external onlyOwner {
        require(newFee <= 10000, Errors.EXCEED_PLATFORM_FEE_VALUE);
        platformFee = newFee;

        emit UpdatePlateformFee(newFee);
    }

    function setBackendSigner(address _bkSigner) external override onlyOwner {
        if (_bkSigner == address(0)) revert AddressNotNull();
        backendSigner = _bkSigner;

        emit SetBackendSigner(_bkSigner);
    }


    /// @dev buy NFT which is listed on marketplace with WETH token
    /// @param v - signature param
    /// @param r - signature param
    /// @param s - signature param
    /// @param _info - info of selling NFT
    function buySellItem(
        uint8 v,
        bytes32 r,
        bytes32 s,
        NftInfo calldata _info
    ) external whenNotPaused onlyNewSignature(v, r, s) {
        //at initial time  isEnableGenesisListing is false and nobody can list
        if(isEnableGenesisListing == false) revert ListingIsNotEnabled();

        require(
            _checkBuyNFTSignature(v, r, s, _info),
            Errors.SIGNATURE_IS_WRONG
        );
        uint256 fee = (_info.price * platformFee) / 10000;
        uint256 sellerProceeds = _info.price - fee;

        IERC20Upgradeable erc20Token = IERC20Upgradeable(
            _getPriceTokenAddress(_info.priceUnit)
        );
        if (
            keccak256(abi.encodePacked(_info.sellType)) ==
            keccak256(abi.encodePacked("fixed-listing"))
        ) {
            //fixed sell _info.userAddr is seller and msg.sender is buyer
            erc20Token.safeTransferFrom(
                msg.sender,
                _info.userAddr,
                sellerProceeds
            );
            erc20Token.safeTransferFrom(msg.sender, revenueWallet, fee);
            _transfer(
                _info.nftContract,
                _info.userAddr,
                msg.sender,
                _info.nftId
            );
            emit FixedItemSuccessful(
                _info.nftContract,
                _info.nftId,
                _info.price,
                _info.priceUnit,
                msg.sender
            );
        } else if (
            keccak256(abi.encodePacked(_info.sellType)) ==
            keccak256(abi.encodePacked("auction-listing"))
        ) {
            //auction sell _info.userAddr is buyer address and msg.sender is seller
            erc20Token.safeTransferFrom(
                _info.userAddr,
                msg.sender,
                sellerProceeds
            );
            erc20Token.safeTransferFrom(_info.userAddr, revenueWallet, fee);
            _transfer(
                _info.nftContract,
                msg.sender,
                _info.userAddr,
                _info.nftId
            );
            emit AuctionSuccessful(
                _info.nftContract,
                _info.nftId,
                _info.price,
                _info.priceUnit,
                _info.userAddr
            );
        } else {
            revert WrongParam();
        }
    }

    /// @dev buy NFT which is added on shopping cart on marketplace frontend
    /// @param v - signature param
    /// @param r - signature param
    /// @param s - signature param
    /// @param _info - info of cart items

    function buyCartItems(
        uint8 v,
        bytes32 r,
        bytes32 s,
        BucketInfo calldata _info
    ) external whenNotPaused onlyNewSignature(v, r, s) {
        require(_checkCartSignature(v, r, s, _info), Errors.SIGNATURE_IS_WRONG);
        require(
            _info.nftContracts.length == _info.nftIds.length,
            Errors.WRONG_CART_INFO
        );
        require(
            _info.nftContracts.length == _info.prices.length,
            Errors.WRONG_CART_INFO
        );
        require(
            _info.nftContracts.length == _info.userAddrs.length,
            Errors.WRONG_CART_INFO
        );
        require(
            _info.nftContracts.length == _info.priceUnits.length,
            Errors.WRONG_CART_INFO
        );
        require(
            _info.nftContracts.length == _info.nftTypes.length,
            Errors.WRONG_CART_INFO
        );

        for (uint256 i = 0; i < _info.nftIds.length; i++) {
            uint256 fee = (_info.prices[i] * platformFee) / 10000;
            uint256 sellerProceeds = _info.prices[i] - fee;

            IERC20Upgradeable erc20Token = IERC20Upgradeable(
                _getPriceTokenAddress(_info.priceUnits[i])
            );

            erc20Token.safeTransferFrom(
                msg.sender,
                _info.userAddrs[i],
                sellerProceeds
            );
            erc20Token.safeTransferFrom(msg.sender, revenueWallet, fee);
            _transfer(
                _info.nftContracts[i],
                _info.userAddrs[i],
                msg.sender,
                _info.nftIds[i]
            );

            if (_info.nftTypes[i] == 0) {
                //if the cart items contain genesis nft when the isEnableGenesisListing is false then revert the function
                if(isEnableGenesisListing == false) revert ListingIsNotEnabled();

                //nft is soldier
                emit FixedItemSuccessful(
                    _info.nftContracts[i],
                    _info.nftIds[i],
                    _info.prices[i],
                    _info.priceUnits[i],
                    msg.sender
                );
            } else if (_info.nftTypes[i] == 1) {
                // nft is weapon
                // 1:fixed selll
                emit LootBuySellSuccess(
                    1,
                    _info.userAddrs[i],
                    msg.sender,
                    _info.prices[i],
                    _info.priceUnits[i],
                    _info.nftIds[i],
                    _info.nftContracts[i]
                );
            } else {
                revert WrongParam();
            }
        }
    }

    /// @dev called by fixed and auction sell
    /// @param v - signature param
    /// @param r - signature param
    /// @param s - signature param
    /// @param _info - info of loot items
    function buySellLootBoxes(
        uint8 v,
        bytes32 r,
        bytes32 s,
        LootBuySellInfo calldata _info
    ) external whenNotPaused onlyNewSignature(v, r, s) {
        require(
            _checkWeaponBuySellSignature(v, r, s, _info),
            Errors.SIGNATURE_IS_WRONG
        );
        require(
            _info.nftIds.length == _info.prices.length,
            Errors.WRGON_LOOTBOX_BY_SELL
        );
        require(
            _info.nftIds.length == _info.userAddrs.length,
            Errors.WRGON_LOOTBOX_BY_SELL
        );
        require(
            _info.nftIds.length == _info.priceUnits.length,
            Errors.WRGON_LOOTBOX_BY_SELL
        );
        require(
            _info.nftIds.length == _info.userAddrs.length,
            Errors.WRGON_LOOTBOX_BY_SELL
        );

        if (
            keccak256(abi.encodePacked(_info.buySellType)) ==
            keccak256(abi.encodePacked("fixed-listing"))
        ) {
            //fixed sell
            for (uint256 i = 0; i < _info.nftIds.length; i++) {
                _buySellLootBoxes(
                    1, //fixed sell
                    _info.priceUnits[i],
                    _info.prices[i],
                    msg.sender,
                    _info.userAddrs[i],
                    _info.nftIds[i],
                    _info.nftContract
                );
            }
        } else if(keccak256(abi.encodePacked(_info.buySellType)) ==
            keccak256(abi.encodePacked("auction-listing"))){
            //auction sell
            for (uint256 i = 0; i < _info.nftIds.length; i++) {
                _buySellLootBoxes(
                    2, //fixed sell
                    _info.priceUnits[i],
                    _info.prices[i],
                    _info.userAddrs[i],
                    msg.sender,
                    _info.nftIds[i],
                    _info.nftContract
                );
            }
        } else {
            revert WrongParam();
        }
    }

    function _getPriceTokenAddress(
        uint256 priceUnit
    ) internal view returns (address) {
        //priceUnit can be 0, 1, 2
        require(priceUnit < 3, Errors.PRICE_UNIT_WRONG);
        //if priceUnit = 0 then weth
        //else if priceUnit = 1 then ufo
        //else if priceUnit = 2 then usdt
        address priceToken;
        if (priceUnit == 0) {
            priceToken = wethAddr;
        } else if (priceUnit == 1) {
            priceToken = ufoAddress;
        } else if (priceUnit == 2) {
            priceToken = usdtAddress;
        }
        return priceToken;
    }

    function _buySellLootBoxes(
        uint256 buySellType,
        uint256 priceUnit,
        uint256 price,
        address buyer,
        address seller,
        uint256 nftId,
        address contractAddr
    ) internal whenNotPaused {
        IERC20Upgradeable erc20Token = IERC20Upgradeable(
            _getPriceTokenAddress(priceUnit)
        );
        uint256 fee = (price * platformFee) / 10000;
        uint256 sellerProceeds = price - fee;
        erc20Token.safeTransferFrom(buyer, seller, sellerProceeds);
        erc20Token.safeTransferFrom(buyer, revenueWallet, fee);
        _transferLootBox(contractAddr, seller, buyer, nftId);
        emit LootBuySellSuccess(
            buySellType,
            seller,
            buyer,
            price,
            priceUnit,
            nftId,
            contractAddr
        );
    }

    /// @dev claim UAP on marketplace frontend
    /// @param v - signature param
    /// @param r - signature param
    /// @param s - signature param
    /// @param _info - info of selling NFT
    function claimUAP(
        uint8 v,
        bytes32 r,
        bytes32 s,
        UAPClaimInfo calldata _info
    ) external whenNotPaused onlyNewSignature(v, r, s) {
        require(
            _checkClaimUAPSignature(v, r, s, _info),
            Errors.SIGNATURE_IS_WRONG
        );

        IEscrow(uapEscrow).transferUAP(_info.user, _info.amount);
        emit ClaimUAP(_info.user, _info.amount);
    }

    ///@dev transfer loot box to other users
    ///@param _sender loot Owner
    ///@param _receiver receiver address of loot box
    ///@param _tokenId token id to transfer
    function _transferLootBox(
        address _weaponContract,
        address _sender,
        address _receiver,
        uint256 _tokenId
    ) internal {
        IERC721Upgradeable _nftContract = IERC721Upgradeable(_weaponContract);
        _nftContract.safeTransferFrom(_sender, _receiver, _tokenId, "");
    }

    /// @dev Transfers an NFT owned by seller to another address.
    /// @param _nftAddress - The address of the NFT.
    /// @param _seller - Address to transfer NFT from.
    /// @param _buyer - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(
        address _nftAddress,
        address _seller,
        address _buyer,
        uint256 _tokenId
    ) internal {
        IERC721Upgradeable _nftContract = IERC721Upgradeable(_nftAddress);
        // It will throw if transfer fails
        _nftContract.safeTransferFrom(_seller, _buyer, _tokenId, "");
    }

    function withdraw(address addr) external onlyOwner {
        //WETH transfer
        IERC20Upgradeable wethToken = IERC20Upgradeable(wethAddr);
        uint256 native = wethToken.balanceOf(address(this));
        wethToken.safeTransfer(addr, native);

        //USDT transfer
        IERC20Upgradeable usdtToken = IERC20Upgradeable(usdtAddress);
        uint256 usdt = usdtToken.balanceOf(address(this));
        usdtToken.safeTransfer(addr, usdt);

        //UFO transfer
        IERC20Upgradeable ufoToken = IERC20Upgradeable(ufoAddress);
        uint256 ufo = ufoToken.balanceOf(address(this));
        ufoToken.safeTransfer(addr, ufo);

        emit Withdraw(addr, native, usdt, ufo);
    }

    modifier onlyNewSignature(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) {
        bytes memory signature = concatSignature(v, r, s);
        if (alreadyUsedSignature[signature]) {
            revert InvalidSignature();
        } else {
            alreadyUsedSignature[signature] = true;
            _;
        }
    }

    //test function
    // function transferUAP(address recipient, uint256 amount) external {
    //     IEscrow(uapEscrow).transferUAP(recipient, amount);
    // }
}
