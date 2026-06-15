//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./../interfaces/IWeapon.sol";
import "./../interfaces/ISuperGalaticFactory.sol";
import "./../Errors.sol";
import "./../interfaces/IBaseType.sol";

error AddressNotNull();
error CannotTransfer();
/**
 * @notice SuperGalatic NFT Contract
 */
contract Weapon is
    Initializable,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable,
    IWeapon,
    IBaseType
{
    struct WeaponInfo {
        uint256 level;
        Rarity rarity;
        WeaponType weaponType;
        bool isOpened;
        address user;
    }

    address public admin; // admin will be a multisig contract address
    address public factory;

    // tokenID => weaponInfo
    mapping(uint256 => WeaponInfo) public weaponInfos;

    /**
     * @notice event is omitted when user mint gensis NFT
     * @param weaponId weapon NFT id
     * @param owner weapon NFT mint address
     * @param rarity rarity of minted NFT
     * @param level level of minted NFT
     * @param weaponType weapon type of NFT
     */
    event openLootBoxEvent(
        uint256 weaponId,
        address owner,
        uint256 rarity,
        uint256 level,
        uint256 weaponType
    );

    /**
     * @notice event is omitted when user mint gensis NFT
     * @param weaponId weapon NFT id
     * @param level updated level of minted NFT
     * @param rarity rarity of minted NFT
     */
    event updateWeaponEvent(uint256 weaponId, uint256 level, uint256 rarity);

    /**
     * @notice event when user purchase the loot
     * @param tokenIds loot amount to purchase
     * @param owner address of purchased loot owner
     * @param totalPrice loot amount to purchase
     * @param tokenType address of purchased loot owner
     */
    event purchaseLootEvent(
        uint256[] tokenIds,
        address owner,
        uint256 totalPrice,
        uint256 tokenType
    );

    /**
     * @notice event when giftReciver receives :quantities' of weapons as gift
     * @param tokenIds weapon amount
     * @param giftReceiver gift receiver
     */
    event purchaseAndSendGiftEvent(
        uint256[] tokenIds,
        address giftSender,
        address giftReceiver,
        uint256 totalPrice,
        uint256 tokenType
    );

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the UFO NFT contract with dependent parameters
     * @param _admin Address of the admin contract
     * @param _factory SuperGalatic Factory address
     */
    function initialize(
        address _admin,
        address _factory
    ) external override initializer {
        if (_admin == address(0) || _factory == address(0))
            revert AddressNotNull();

        __ERC721_init("SGWeapon", "SGW");
        __ERC721Holder_init();
        __Ownable_init();
        transferOwnership(_admin);
        admin = _admin;
        factory = _factory;
    }

    /**
     * @notice function call to generate genesis nft
     * @param _owner Address that generate new weapon
     */
    function openLootBox(
        address _owner,
        uint256 _rarity,
        uint256 _weaponType,
        uint256 _tokenId
    ) external override onlyFactory {
        // users can open it after transfer it so this condition is wrong
        // require(weaponInfos[_tokenId].user == _owner, Errors.NO_PURCHASE_LOOT_TO_MINT);

        weaponInfos[_tokenId].level = 0;
        weaponInfos[_tokenId].rarity = (Rarity)(_rarity);
        weaponInfos[_tokenId].weaponType = (WeaponType)(_weaponType);
        weaponInfos[_tokenId].isOpened = true;

        emit openLootBoxEvent(_tokenId, _owner, _rarity, 0, _weaponType);
    }

    /**
     * @notice user purchase the loot box
     * @param _quantity amount of loot box to transfer
     * @param _user lootbox owner
     */

    function purchaseLootBox(
        uint256 _quantity,
        address _user,
        uint256 _totalPrice,
        uint256 _tokenType
    ) external override onlyFactory {
        uint256[] memory ids = _purchaseLootBox(_quantity, _user);
        emit purchaseLootEvent(ids, _user, _totalPrice, _tokenType);
    }

    /**
     * @notice user purchase the loot box and send it to _user as gift
     * @param _quantity amount of loot box to transfer
     * @param _sender user who send the lootbox as gift
     * @param _receiver user whom to receive the lootbox as gift
     */

    function purchaseLootBoxAndSendGift(
        uint256 _quantity,
        address _sender,
        address _receiver,
        uint256 _totalPrice,
        uint256 _tokenType
    ) external override onlyFactory {
        uint256[] memory ids = _purchaseLootBox(_quantity, _receiver);
        emit purchaseAndSendGiftEvent(
            ids,
            _sender,
            _receiver,
            _totalPrice,
            _tokenType
        );
    }

    function _purchaseLootBox(
        uint256 _quantity,
        address _user
    ) internal returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](_quantity);
        for (uint256 i = 0; i < _quantity; ) {
            uint256 newID = totalSupply() + 1;
            _safeMint(_user, newID);
            weaponInfos[newID].user = _user;
            weaponInfos[newID].isOpened = false;
            ids[i] = newID;
            unchecked {
                i++;
            }
        }
        return ids;
    }

    function updateWeaponLevel(uint256 weaponId) external override onlyFactory {
        WeaponInfo storage info = weaponInfos[weaponId];
        require(info.isOpened, Errors.LOOTBOX_NOT_OPENED);
        info.level = info.level + 1;
        emit updateWeaponEvent(weaponId, info.level, uint256(info.rarity));
    }

    function getWeaponInfo(
        uint256 weaponId
    )
        external
        view
        override
        returns (uint256 level, uint256 rarity, uint256 weaponType)
    {
        WeaponInfo memory info = weaponInfos[weaponId];
        return (info.level, (uint256)(info.rarity), (uint256)(info.weaponType));
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        //reject transfer request from sphere beam marketplace
        if (msg.sender == 0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC)
            revert CannotTransfer();
        super._transfer(from, to, tokenId);
    }

    modifier onlyFactory() {
        require(msg.sender == factory, Errors.ONLY_FACTORY_CAN_CALL);
        _;
    }
}
