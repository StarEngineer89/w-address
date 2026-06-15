//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract EIP712UfoMarketplace {
    address public backendSigner;
    struct NftInfo {
        uint256 nftId;
        address nftContract;
        string sellType;
        address userAddr;
        uint256 price;
        uint256 priceUnit;
        uint256 start;
        uint256 end;
        uint256 salt;
    }

    struct UAPClaimInfo {
        uint256 amount;
        address user;
        uint256 salt;
    }

    struct BucketInfo {
        uint256[] nftIds;
        address[] nftContracts;
        address[] userAddrs;
        uint256[] prices;
        uint256[] priceUnits;
        uint256[] nftTypes; //if nftType = 0 then nft_soldier, nftType = 1 then nft_weapon, nftType = 2 then land
        uint256 salt;
    }

    struct LootBuySellInfo {
        address nftContract; //weapon contract address. there is only one weapon contract
        uint256[] nftIds;
        uint256[] prices;
        uint256[] priceUnits;
        address[] userAddrs; // seller when fixed sell and buyer on auction sell
        string buySellType; //1: fixed sell, 2: auction sell
        uint256 start; //availabe on auction sell
        uint256 end; //availabe on auction sell
        uint256 salt; //availabe on auction sell
    }

    function setBackendSigner(address _bkSigner) external virtual;

    function _checkBuyNFTSignature(
        uint8 v,
        bytes32 r,
        bytes32 s,
        NftInfo calldata info
    ) internal view returns (bool) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("NftSellInfo")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256(
                    "NftInfo(uint256 nftId,address nftContract,string sellType,address userAddr,uint256 price,uint256 priceUnit,uint256 start,uint256 end,uint256 salt)"
                ),
                info.nftId,
                info.nftContract,
                keccak256(bytes(info.sellType)),
                info.userAddr,
                info.price,
                info.priceUnit,
                info.start,
                info.end,
                info.salt
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct)
        );
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        require(signer == backendSigner, "Invalid signature");
        return true;
    }

    function _checkClaimUAPSignature(
        uint8 v,
        bytes32 r,
        bytes32 s,
        UAPClaimInfo calldata info
    ) internal view returns (bool) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("UAPClaimInfo")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256(
                    "UAPClaimInfo(uint256 amount,address user,uint256 salt)"
                ),
                info.amount,
                info.user,
                info.salt
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct)
        );
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        require(signer == backendSigner, "Invalid signature");
        return true;
    }

    function _checkCartSignature(
        uint8 v,
        bytes32 r,
        bytes32 s,
        BucketInfo calldata info
    ) internal view returns (bool) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("BucketInfo")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256(
                    "BucketInfo(uint256[] nftIds,address[] nftContracts,address[] userAddrs,uint256[] prices,uint256[] priceUnits,uint256[] nftTypes,uint256 salt)"
                ),
                keccak256(abi.encodePacked(info.nftIds)),
                keccak256(abi.encodePacked(info.nftContracts)),
                keccak256(abi.encodePacked(info.userAddrs)),
                keccak256(abi.encodePacked(info.prices)),
                keccak256(abi.encodePacked(info.priceUnits)),
                keccak256(abi.encodePacked(info.nftTypes)),
                info.salt
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct)
        );
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        require(signer == backendSigner, "Invalid backend Signer");
        return true;
    }

    function _checkWeaponBuySellSignature(
        uint8 v,
        bytes32 r,
        bytes32 s,
        LootBuySellInfo calldata info
    ) internal view returns (bool) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("LootBuySellInfo")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256(
                    "LootBuySellInfo(address nftContract,uint256[] nftIds,uint256[] prices,uint256[] priceUnits,address[] userAddrs,string buySellType,uint256 start,uint256 end,uint256 salt)"
                ),
                info.nftContract,
                keccak256(abi.encodePacked(info.nftIds)),
                keccak256(abi.encodePacked(info.prices)),
                keccak256(abi.encodePacked(info.priceUnits)),
                keccak256(abi.encodePacked(info.userAddrs)),
                keccak256(bytes(info.buySellType)),
                info.start,
                info.end,
                info.salt
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct)
        );
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
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
