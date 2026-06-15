//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./../interfaces/IBaseType.sol";
import "./../Errors.sol";
interface IFactoryHelper {
    function getNftUAPCost(
        uint256 rarity,
        uint256 level
    ) external view returns (uint256);
    function getWeaponUAPCost(
        uint256 rarity,
        uint256 weaponType,
        uint256 level
    ) external view returns (uint256);
}

contract FactoryHelper is Ownable, IBaseType, IFactoryHelper {
    //nft rarity => level => uapCost
    mapping(Rarity => mapping(uint256 => uint256)) public nftUAPCostTable;
    //weapon rarity => type => level => uapCost
    mapping(Rarity => mapping(WeaponType => mapping(uint256 => uint256)))
        public weaponUAPCostTable;

    event UpdateGenesisCosts(uint256 rarity, uint256[] levelCosts);
    event UpdateWeaponCosts(
        uint256 rarity,
        uint256 weaponType,
        uint256[] levelCosts
    );

    /**
        initialize uap cost table
     */

    constructor(address _admin) {
        initNFTUAPCostTable();
        initWeaponUAPCostTable();
        transferOwnership(_admin);
    }
    function initNFTUAPCostTable() private {
        nftUAPCostTable[Rarity.White][1] = 1000;
        nftUAPCostTable[Rarity.White][2] = 5000;
        nftUAPCostTable[Rarity.White][3] = 20000;
        nftUAPCostTable[Rarity.White][4] = 30000;
        nftUAPCostTable[Rarity.White][5] = 40000;

        nftUAPCostTable[Rarity.Green][1] = 1200;
        nftUAPCostTable[Rarity.Green][2] = 6000;
        nftUAPCostTable[Rarity.Green][3] = 24000;
        nftUAPCostTable[Rarity.Green][4] = 36000;
        nftUAPCostTable[Rarity.Green][5] = 48000;

        nftUAPCostTable[Rarity.Blue][1] = 1500;
        nftUAPCostTable[Rarity.Blue][2] = 7500;
        nftUAPCostTable[Rarity.Blue][3] = 30000;
        nftUAPCostTable[Rarity.Blue][4] = 45000;
        nftUAPCostTable[Rarity.Blue][5] = 60000;
        nftUAPCostTable[Rarity.Blue][6] = 75000;

        nftUAPCostTable[Rarity.Purple][1] = 2000;
        nftUAPCostTable[Rarity.Purple][2] = 10000;
        nftUAPCostTable[Rarity.Purple][3] = 40000;
        nftUAPCostTable[Rarity.Purple][4] = 60000;
        nftUAPCostTable[Rarity.Purple][5] = 80000;
        nftUAPCostTable[Rarity.Purple][6] = 100000;
    }

    function initWeaponUAPCostTable() private {
        weaponUAPCostTable[Rarity.White][WeaponType.Range][1] = 2000;
        weaponUAPCostTable[Rarity.White][WeaponType.Range][2] = 10000;
        weaponUAPCostTable[Rarity.White][WeaponType.Range][3] = 40000;
        weaponUAPCostTable[Rarity.White][WeaponType.Range][4] = 60000;

        weaponUAPCostTable[Rarity.Green][WeaponType.Range][1] = 2400;
        weaponUAPCostTable[Rarity.Green][WeaponType.Range][2] = 12000;
        weaponUAPCostTable[Rarity.Green][WeaponType.Range][3] = 48000;
        weaponUAPCostTable[Rarity.Green][WeaponType.Range][4] = 72000;

        weaponUAPCostTable[Rarity.Blue][WeaponType.Range][1] = 3000;
        weaponUAPCostTable[Rarity.Blue][WeaponType.Range][2] = 15000;
        weaponUAPCostTable[Rarity.Blue][WeaponType.Range][3] = 60000;
        weaponUAPCostTable[Rarity.Blue][WeaponType.Range][4] = 90000;
        weaponUAPCostTable[Rarity.Blue][WeaponType.Range][5] = 120000;

        weaponUAPCostTable[Rarity.Purple][WeaponType.Range][1] = 4000;
        weaponUAPCostTable[Rarity.Purple][WeaponType.Range][2] = 20000;
        weaponUAPCostTable[Rarity.Purple][WeaponType.Range][3] = 80000;
        weaponUAPCostTable[Rarity.Purple][WeaponType.Range][4] = 120000;
        weaponUAPCostTable[Rarity.Purple][WeaponType.Range][5] = 160000;

        weaponUAPCostTable[Rarity.White][WeaponType.Melee][1] = 1500;
        weaponUAPCostTable[Rarity.White][WeaponType.Melee][2] = 7500;
        weaponUAPCostTable[Rarity.White][WeaponType.Melee][3] = 30000;
        weaponUAPCostTable[Rarity.White][WeaponType.Melee][4] = 45000;

        weaponUAPCostTable[Rarity.Green][WeaponType.Melee][1] = 1800;
        weaponUAPCostTable[Rarity.Green][WeaponType.Melee][2] = 9000;
        weaponUAPCostTable[Rarity.Green][WeaponType.Melee][3] = 36000;
        weaponUAPCostTable[Rarity.Green][WeaponType.Melee][4] = 54000;

        weaponUAPCostTable[Rarity.Blue][WeaponType.Melee][1] = 2250;
        weaponUAPCostTable[Rarity.Blue][WeaponType.Melee][2] = 11250;
        weaponUAPCostTable[Rarity.Blue][WeaponType.Melee][3] = 45000;
        weaponUAPCostTable[Rarity.Blue][WeaponType.Melee][4] = 67500;
        weaponUAPCostTable[Rarity.Blue][WeaponType.Melee][5] = 90000;

        weaponUAPCostTable[Rarity.Purple][WeaponType.Melee][1] = 3000;
        weaponUAPCostTable[Rarity.Purple][WeaponType.Melee][2] = 15000;
        weaponUAPCostTable[Rarity.Purple][WeaponType.Melee][3] = 60000;
        weaponUAPCostTable[Rarity.Purple][WeaponType.Melee][4] = 900000;
        weaponUAPCostTable[Rarity.Purple][WeaponType.Melee][5] = 120000;
    }

    function getNftUAPCost(
        uint256 rarity,
        uint256 level
    ) external view override returns (uint256) {
        return nftUAPCostTable[Rarity(rarity)][level];
    }

    function getWeaponUAPCost(
        uint256 rarity,
        uint256 weaponType,
        uint256 level
    ) external view override returns (uint256) {
        return
            weaponUAPCostTable[Rarity(rarity)][WeaponType(weaponType)][level];
    }

    /**
     *@notice update plasma address
     *@param _rarity rarity to update the costs
     */
    function getNFTUapCostTable(
        uint256 _rarity
    ) external view returns (uint256[5] memory) {
        if (
            Rarity(_rarity) == Rarity.White || Rarity(_rarity) == Rarity.Green
        ) {
            return [
                nftUAPCostTable[Rarity(_rarity)][1],
                nftUAPCostTable[Rarity(_rarity)][2],
                nftUAPCostTable[Rarity(_rarity)][3],
                nftUAPCostTable[Rarity(_rarity)][4],
                0
            ];
        } else {
            return [
                nftUAPCostTable[Rarity(_rarity)][1],
                nftUAPCostTable[Rarity(_rarity)][2],
                nftUAPCostTable[Rarity(_rarity)][3],
                nftUAPCostTable[Rarity(_rarity)][4],
                nftUAPCostTable[Rarity(_rarity)][5]
            ];
        }
    }

    /**
     *@notice update plasma address
     *@param _rarity rarity to update the costs
     */
    function getWeaponUapCostTable(
        uint256 _rarity,
        uint256 _type
    ) external view returns (uint256[5] memory) {
        if (
            Rarity(_rarity) == Rarity.White || Rarity(_rarity) == Rarity.Green
        ) {
            return [
                weaponUAPCostTable[Rarity(_rarity)][WeaponType(_type)][1],
                weaponUAPCostTable[Rarity(_rarity)][WeaponType(_type)][2],
                weaponUAPCostTable[Rarity(_rarity)][WeaponType(_type)][3],
                weaponUAPCostTable[Rarity(_rarity)][WeaponType(_type)][4],
                0
            ];
        } else {
            return [
                weaponUAPCostTable[Rarity(_rarity)][WeaponType(_type)][1],
                weaponUAPCostTable[Rarity(_rarity)][WeaponType(_type)][2],
                weaponUAPCostTable[Rarity(_rarity)][WeaponType(_type)][3],
                weaponUAPCostTable[Rarity(_rarity)][WeaponType(_type)][4],
                weaponUAPCostTable[Rarity(_rarity)][WeaponType(_type)][5]
            ];
        }
    }

    /**
     *@notice update plasma address
     *@param _rarity rarity to update the costs
     *@param _levelCosts costs array for update
     */
    function updateNFTUapCostTable(
        uint256 _rarity,
        uint256[] memory _levelCosts
    ) external onlyOwner {
        require(
            _rarity >= uint256(Rarity.White) &&
                _rarity <= uint256(Rarity.Purple),
            Errors.CANNOT_UPDATE
        );
        for (uint256 i = 0; i < _levelCosts.length; i++) {
            nftUAPCostTable[Rarity(_rarity)][i + 1] = _levelCosts[i];
        }

        emit UpdateGenesisCosts(_rarity, _levelCosts);
    }

    /**
     *@notice update plasma address
     *@param _rarity rarity to update the costs
     *@param _levelCosts costs array for update
     */
    function updateWeaponUapCostTable(
        uint256 _rarity,
        uint256 _type,
        uint256[] memory _levelCosts
    ) external onlyOwner {
        require(
            _rarity >= uint256(Rarity.White) &&
                _rarity <= uint256(Rarity.Purple),
            Errors.CANNOT_UPDATE
        );
        for (uint256 i = 0; i < _levelCosts.length; i++) {
            weaponUAPCostTable[Rarity(_rarity)][WeaponType(_type)][
                i + 1
            ] = _levelCosts[i];
        }

        emit UpdateWeaponCosts(_rarity, _type, _levelCosts);
    }
}
