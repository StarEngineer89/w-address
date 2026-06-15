//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



/**
 @notice NFT UFO contract function
 @dev The interface only currently contains only breeding function. Any other functions can be added as per requirement
 */
interface IBaseType {
    enum Rarity {
        White,
        Green,
        Blue,
        Purple
    }

    enum WeaponType {
        Range, 
        Melee
    }
}