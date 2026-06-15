//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract EIP712SuperGalaticFactory {
    address public backendSigner;

    struct WeaponInfo {
        uint256 rarity;
        uint256 weaponType;
        address owner;
        uint256 salt;
        uint256 tokenId;
    }
    function setBackendSigner(address _bkSigner) external virtual;

    //this function is used to check the signature when purchase the lootbox
    //called by super galatic factory smart contract
    function _checkWeaponPurchaseSignature(
        uint8 v,
        bytes32 r,
        bytes32 s,
        WeaponInfo calldata info
    ) internal view returns (bool) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("WeaponInfo")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256(
                    "WeaponInfo(uint256 rarity,uint256 weaponType,address owner,uint256 salt,uint256 tokenId)"
                ),
                info.rarity,
                info.weaponType,
                info.owner,
                info.salt,
                info.tokenId
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct)
        );
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        require(info.owner == msg.sender, "Wrong Loot owner");
        require(signer == backendSigner, "Invalid backend Signer");
        return true;
    }

    function concatSignature(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bytes memory) {
        return abi.encodePacked(r, s, v);
    }
}
