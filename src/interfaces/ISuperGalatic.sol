//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 @notice NFT UFO contract function
 @dev The interface only currently contains only breeding function. Any other functions can be added as per requirement
 */
interface ISuperGalatic {
    function initialize(
        address _admin,
        address _factory,
        uint256 _categoryId
    ) external;

    function createGenesis(address minter, uint256 priceUnit) external;
    
    function createRandomGenesis(address minter, uint256 priceUnit, uint256 price) external;

    function updateBody(uint256 bodyType, uint256 tokenId) external;

    function getBodyInfo(uint256 tokenId, uint256 bodyType) external view returns (uint256 level, uint256 rarity);
}
