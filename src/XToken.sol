//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract XToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER = keccak256('MINTER');
    uint8 public decimal = 18;
    constructor(
        string memory name,
        string memory symbol,
        uint256 init_supply,
        uint8 _decimal,
        address minter
    ) ERC20(name, symbol) {
        _mint(minter, init_supply);
        _grantRole(MINTER, minter);
        decimal = _decimal;
    }

    function decimals() public view override returns (uint8) {
        return decimal;
    }

    function mint(address _to, uint256 _amount) public onlyMinter returns (uint256) {
        require(_amount != 0, 'Amount should be greater than 0');
        _mint(_to, _amount);
        return _amount;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER, msg.sender), 'Only Address with minter role can mint tokens');
        _;
    }
}
