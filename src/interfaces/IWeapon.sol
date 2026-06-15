//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 @notice NFT UFO contract function
 @dev The interface only currently contains only breeding function. Any other functions can be added as per requirement
 */
interface IWeapon {
    function initialize(address _admin, address _factory) external;

    function openLootBox(
        address _owner,
        uint256 _rarity,
        uint256 _weaponType,
        uint256 _tokenId
    ) external;

    function updateWeaponLevel(uint256 weaponId) external;

    function purchaseLootBox(uint256 _quantity, address _user, uint256 _totalPrice, uint256 _tokenType) external;

    function purchaseLootBoxAndSendGift(uint256 _quantity, address _sender, address _receiver, uint256 _totalPrice, uint256 _tokenType) external;

    function getWeaponInfo(uint256 weaponId)
        external
        view
        returns (
            uint256 level,
            uint256 rarity,
            uint256 weaponType
        );
}
