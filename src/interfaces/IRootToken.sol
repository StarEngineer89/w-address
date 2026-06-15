
pragma solidity ^0.8.7;

interface IRootToken {
    function publicMint(address user, uint256 amount) external;
}