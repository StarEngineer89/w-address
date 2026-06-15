//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 @notice NFT factory contract function
 @dev 
 */
interface ISuperGalaticFactory {
    function isSuperGalaticNFTContract(address _nftAddress) external view returns (bool);
}
