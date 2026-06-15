//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./../interfaces/ISuperGalatic.sol";
import "./../interfaces/IBaseType.sol";
import "./../interfaces/ISuperGalaticFactory.sol";
import "./../Errors.sol";

error AddressNotNull();
error CannotTransfer();
/**
 * @notice SuperGalatic NFT Contract
 */
contract SuperGalatic is
    Initializable,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable,
    ISuperGalatic,
    IBaseType
{
    enum BodyType {
        None,
        Head, //Head
        Chest, //Chest
        Arms, //Arms
        Legs, //Legs
        Ears, //Ears
        Backpack //Backpack
    }
    struct BodyInfo {
        uint256 level;
        Rarity rarity;
    }

    uint256 public categoryId;
    address public factory;

    // tokenID => (bodyType => bodyInfo)
    mapping(uint256 => mapping(uint256 => BodyInfo)) public nftInfos;
    uint256 private nonce;
    /**
     * @notice event is omitted when user mint gensis NFT
     * @param nftId address of the pool
     */
    event mintGensisNFT(
        uint256 nftId,
        address owner,
        uint256 categoryId,
        uint256 priceUnit
    );

    /**
     * @notice event is omitted when user mint random gensis NFT
     * @param nftId address of the pool
     */
    event mintRandomGensisNFT(
        uint256 nftId,
        address owner,
        uint256 categoryId,
        uint256[] bodyTypes,
        uint256 priceUnit,
        uint256 price
    );

    /**
     * @notice event is omitted when user mint gensis NFT
     * @param nftId address of the pool
     */
    event updateBodyPart(
        address nftContract,
        uint256 nftId,
        uint256 bodyType,
        uint256 bodyLevel,
        uint256 bodyRarity
    );

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the UFO NFT contract with dependent parameters
     * @param _admin Address of the admin contract
     */
    function initialize(
        address _admin,
        address _factory,
        uint256 _categoryId
    ) external override initializer {
        if (_admin == address(0) || _factory == address(0))
            revert AddressNotNull();
        __ERC721_init("SuperGalatic", "SuperGalatic");
        __ERC721Holder_init();
        __Ownable_init();
        transferOwnership(_admin);
        categoryId = _categoryId;
        factory = _factory;
    }

    /**
     * @notice function call to generate genesis nft
     * @param minter Address that receives the newly generated NFT
     */
    function createGenesis(
        address minter,
        uint256 priceUnit
    ) external override onlyFactory {
        uint256 newID = totalSupply() + 1;
        require(newID < 10001, Errors.EXCEED_AMOUNT);
        _safeMint(minter, newID);

        nftInfos[newID][uint256(BodyType.Head)] = BodyInfo(0, Rarity.White);
        nftInfos[newID][uint256(BodyType.Arms)] = BodyInfo(0, Rarity.White);
        nftInfos[newID][uint256(BodyType.Backpack)] = BodyInfo(0, Rarity.White);
        nftInfos[newID][uint256(BodyType.Chest)] = BodyInfo(0, Rarity.White);
        nftInfos[newID][uint256(BodyType.Ears)] = BodyInfo(0, Rarity.White);
        nftInfos[newID][uint256(BodyType.Legs)] = BodyInfo(0, Rarity.White);

        emit mintGensisNFT(newID, minter, categoryId, priceUnit);
    }

    /**
     * @notice function call to generate genesis nft with random rarity
     * @param minter Address that receives the newly generated NFT
     */
    function createRandomGenesis(
        address minter,
        uint256 priceUnit,
        uint256 price
    ) external override onlyFactory {
        uint256 newID = totalSupply() + 1;
        require(newID < 10001, Errors.EXCEED_AMOUNT);
        _safeMint(minter, totalSupply() + 1);
        Rarity head = getRandomRarity(newID, 0);
        Rarity arms = getRandomRarity(newID, 1);
        Rarity backpack = getRandomRarity(newID, 2);
        Rarity chest = getRandomRarity(newID, 3);
        Rarity ears = getRandomRarity(newID, 4);
        Rarity legs = getRandomRarity(newID, 5);
        nftInfos[newID][uint256(BodyType.Head)] = BodyInfo(0, head);
        nftInfos[newID][uint256(BodyType.Arms)] = BodyInfo(0, arms);
        nftInfos[newID][uint256(BodyType.Backpack)] = BodyInfo(0, backpack);
        nftInfos[newID][uint256(BodyType.Chest)] = BodyInfo(0, chest);
        nftInfos[newID][uint256(BodyType.Ears)] = BodyInfo(0, ears);
        nftInfos[newID][uint256(BodyType.Legs)] = BodyInfo(0, legs);
        uint256[] memory bodyTypes = new uint256[](6);
        bodyTypes[0] = uint256(head);
        bodyTypes[1] = uint256(arms);
        bodyTypes[2] = uint256(backpack);
        bodyTypes[3] = uint256(chest);
        bodyTypes[4] = uint256(ears);
        bodyTypes[5] = uint256(legs);
        emit mintRandomGensisNFT(
            newID,
            minter,
            categoryId,
            bodyTypes,
            priceUnit,
            price
        );
    }

    /**
     * @notice upgrade body part of nft of which id is token id
     * @param bodyType bodytype need to be upgrade
     * @param tokenId token id of NFT
     */
    function updateBody(
        uint256 bodyType,
        uint256 tokenId
    ) external override onlyFactory {
        BodyInfo storage info = nftInfos[tokenId][bodyType];
        info.level = info.level + 1;
        emit updateBodyPart(
            address(this),
            tokenId,
            bodyType,
            info.level,
            uint256(info.rarity)
        );
    }

    function getBodyInfo(
        uint256 tokenId,
        uint256 bodyType
    ) external view override returns (uint256 level, uint256 rarity) {
        BodyInfo storage info = nftInfos[tokenId][bodyType];
        return (info.level, (uint256)(info.rarity));
    }

    function getRandomRarity(
        uint256 nftId,
        uint256 bodyType
    ) private returns (Rarity rarity) {
        nonce++;
        uint256 randomValue = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    uint(nftId),
                    uint(bodyType),
                    nonce
                )
            )
        ) % 1000;
        if (randomValue < 680) {
            rarity = Rarity.White;
        } else if (randomValue < 980) {
            rarity = Rarity.Green;
        } else if (randomValue < 998) {
            rarity = Rarity.Blue;
        } else {
            rarity = Rarity.Purple;
        }
    }

    function _transfer(address from, address to, uint256 tokenId) internal override {
        //reject transfer request from sphere beam marketplace
        if( msg.sender == 0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC) revert CannotTransfer();    
        super._transfer(from, to, tokenId);
    }

    modifier onlyFactory() {
        require(msg.sender == factory, Errors.ONLY_FACTORY_CAN_CALL);
        _;
    }
}
