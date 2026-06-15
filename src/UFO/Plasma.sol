//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error AlreadySet();
error OnlyWhiteListedCanTransfer();
contract Plasma is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bool public nonTransferability = true;
    address public revenueWallet = 0xB980D88Ae1e9599096e6030fb5381483E4312f31;
    mapping(address => bool) whitelisted;

    event ConfigureWhitelist(address user, bool isWhitelisted);
    event MintEvent(address[] to, uint256[] amount);
    event ConfigureNonTransferability(bool isSet);
    event UpdateRevenueWallet(address revenue);
    constructor(
        string memory name,
        string memory symbol,
        address admin
    ) ERC20(name, symbol) {
        _grantRole(ADMIN_ROLE, admin);
    }

    function updateRevenueWallet(address _revenue) public onlyRole(ADMIN_ROLE) {
        revenueWallet = _revenue;
        emit UpdateRevenueWallet(_revenue);
    }
    function mint(
        address[] memory _to,
        uint256[] memory _amount
    ) public onlyRole(ADMIN_ROLE) returns (uint256) {
        uint256 mintedAmount;
        require(_to.length == _amount.length, "Length mismatch");
        uint256 i;
        for (i = 0; i < _to.length; i++) {
            _mint(_to[i], _amount[i]);
            mintedAmount += _amount[i];
        }

        emit MintEvent(_to, _amount);
        return mintedAmount;
    }

    function configreNonTransferability(
        bool isNon
    ) external onlyRole(ADMIN_ROLE) {
        nonTransferability = isNon;
        emit ConfigureNonTransferability(isNon);
    }

    function configWhitelistUser(
        address user,
        bool isWhitelisted
    ) external onlyRole(ADMIN_ROLE) {
        if (whitelisted[user] == isWhitelisted) revert AlreadySet();
        whitelisted[user] = isWhitelisted;
        emit ConfigureWhitelist(user, isWhitelisted);
    }

    /**
     * disallow normal user to send Plasma to other address.
     * only whitelisted user can send Plasma to other address
     * **_mint function doesn't call this _transfer function**
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        //send to revenueWallet is always enabled
        if (nonTransferability) {
            if (to != revenueWallet) {
                if (!whitelisted[from])
                    revert OnlyWhiteListedCanTransfer();
            }
        }
        super._transfer(from, to, amount);
    }
}
