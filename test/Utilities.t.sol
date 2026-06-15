// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import { PRBTest } from "prb-test/PRBTest.sol";

// common utilities for forge tests
contract Utilities is PRBTest {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));
    bytes32 internal nextRandomHash = keccak256(abi.encodePacked("you feeling lucky punk?"));

    function getNextUserAddress() external returns (address payable) {
        // bytes32 to address conversion
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    // create users with 100 ether balance
    function createUsers(uint256 userNum) external returns (address payable[] memory) {
        address payable[] memory users = new address payable[](userNum);
        for (uint256 i = 0; i < userNum; ++i) {
            address payable user = this.getNextUserAddress();
            vm.deal(user, 100 ether);
            users[i] = user;
        }
        return users;
    }

    // move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
    }

    function mineTime(uint256 numTime) external {
        vm.warp(block.timestamp + numTime);
    }

    function getRandomHash() public returns (bytes32 randomHash) {
        randomHash = nextRandomHash;
        nextRandomHash = keccak256(abi.encodePacked(nextRandomHash));
    }

    // Really hacky random-ish number generator that generates a new bytes32 hash and then converts that to a number.
    // This randomness is completely determinstic because you'll know what the next random number is, but its useful
    // for tests to generate an arbitrary number between [0, maxNum). This is why this function is named
    // getArbitraryUint instead of getRandomUint.
    function getArbitraryUint(uint256 maxNum) public returns (uint256) {
        return uint256(getRandomHash()) % maxNum;
    }

    function getSingleArbitraryUint(uint256 maxNum) public returns (uint256) {
        return uint256(getRandomHash()) % maxNum;
    }
}
