//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

interface IEscrow {
    function transferUAP(address receiver, uint256 amount) external;
}
/**
 * @notice contract stores UAP tokens for claiming from UfoMarketplace contract
 */

 error InvalidCaller(address caller);
 error CannotBeNull();
 error CannotTransfer();
contract Escrow is IEscrow, Ownable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public uap;
    address public marketplace;
    event Witdhraw(address user, uint256 amount);
    constructor(address _uap, address _marketplace, address _admin) {
        if(_uap == address(0) || _marketplace == address(0) || _admin == address(0)) revert CannotBeNull();

        uap = _uap;
        marketplace = _marketplace;
        transferOwnership(_admin);
    }

    function transferUAP(address receiver, uint256 amount) external override onlyMarketplace {
        if(IERC20Upgradeable(uap).balanceOf(address(this)) < amount) revert CannotTransfer();
        IERC20Upgradeable(uap).safeTransfer(receiver, amount);
    }

    modifier onlyMarketplace() {
        if(msg.sender != marketplace) revert InvalidCaller(msg.sender);
        else 
        _;
    }

    function withdraw() external onlyOwner {
        uint256 balance = IERC20Upgradeable(uap).balanceOf(address(this));
        IERC20Upgradeable(uap).safeTransfer(msg.sender, balance);
        emit Witdhraw(msg.sender, balance);
    }
}
