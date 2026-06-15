//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Errors {
    string public constant SHOULD_BE_ON_SELL_STATUS = '1';
    string public constant ONLY_OWNER = '2';
    string public constant INSUFFICIENT_PRICE = '3';
    string public constant SHOULD_NOT_BE_NO_TYPE = '4';
    string public constant SHOULD_BE_MORE_THAN_ZERO = '5';
    string public constant ONLY_FACTORY_CAN_CALL = '6';
    string public constant SHOULD_NOT_BE_OWNER = '7';
    string public constant SHOULD_SAME = '8';
    string public constant SHOULD_BE_NON_ZERO = '9';
    string public constant SHOULD_BE_LESS_THAN_TEN = 'A';
    string public constant ONLY_POOLS_CAN_CALL = 'B';
    string public constant LOCK_IN_BLOCK_LESS_THAN_MIN = 'C';
    string public constant EXCEEDS_MAX_ITERATION = 'D';
    string public constant SHOULD_BE_ZERO = 'E';
    string public constant CANNOT_UPDATE = 'F';
    string public constant APPROVAL_UNSUCCESSFUL = '10';
    string public constant AT_LEAST_ONE_BIDER = '11';
    string public constant ONLY_FEATURE_OF_FLEXI_POOLS = '12';
    string public constant ALREADY_SETUP = '13';
    string public constant ONLY_MINTER = '14';
    string public constant ONLY_SUPERGALATIC_CONTRACT = '15';
    string public constant EXCEED_PLATFORM_FEE_VALUE = '16';
    string public constant SHOULD_BE_DIFFERENT = '17';
    string public constant SHOULD_BE_MORE_THAN_ONE_MINUTE = '18';
    string public constant START_PRICE__IS_BIGGER_THAN_END_PRICE = '19';
    string public constant SIGNATURE_IS_WRONG = '20';
    string public constant SHOULD_NOT_SAME = '21';
    string public constant SHOULD_BE_BIGGER = '22';
    string public constant NOT_WHITELISTED_USER = '23';
    string public constant EXCEED_AMOUNT = '24';
    string public constant WRONG_CART_INFO = '25';
    string public constant NO_PURCHASE_LOOT_TO_MINT = '26';
    string public constant ONLY_MARKETPLACE_CAN_CALL = '27';
    string public constant NOT_WEAPON_ADDRESS = '28';
    string public constant NO_LOOT_TO_TRANSFER = '29';
    string public constant ONLY_BUYER_CAN_CALL = '30';
    string public constant ONLY_SELLER_CAN_CALL = '31';
    string public constant WRGON_LOOTBOX_BY_SELL = '32';
    string public constant LOOTBOX_NOT_OPENED = '33';
    string public constant PRICE_UNIT_WRONG = '34';
}
