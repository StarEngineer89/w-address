//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
error CannotMint();
error CannotNull();
error CannotUpdateTax(uint256 sellTaxPercentage);
error AlreadyInitialized();
error NotAllowedInThisBlockchain();
error AddressNotNull();
/**
 * @notice Standard UAP token contract mintable only by specific minter
 */
contract UAP is Initializable, ERC20BurnableUpgradeable, OwnableUpgradeable {
    uint256 public sellTaxPercentage;
    address public taxWallet;

    /// @notice 50% of total
    uint256 public gameReward; // 210_000_000_000;
    /// @notice 25% of total
    uint256 public liquidityTrading; // 105_000_000_000;
    /// @notice 5% of total
    uint256 public teamAdvisor; // 21_000_000_000;
    /// @notice 15% of total
    uint256 public ecosystemGrowth; // 63_000_000_000;
    /// @notice 5% of total
    uint256 public developmentFund; // 21_000_000_000;

    address public adminWallet; // 0xbCD418c12CD9910DD5B33b1F8eE47eCc562732fC;
    address public liquidityWallet; // 0xE73dEa1340AeCa4AA979438c9950dDfB28DE626C;
    address public teamAdvisorWallet; // 0x20A2968eEfc8c89Aa7b2bb14bf76e22146D6B876;
    //check the address is uniswap pair addresses
    mapping(address => bool) public isPair;
    mapping(address => bool) private bots;

    uint256 public initializeTime;
    uint256 public alreadyClaimedTeamAdvisorTokenAmount;
    bool isInitialized;
    event TaxTransfered(address from, address taxWallet, uint256 tax);
    event TeamAdvisorTokenClaimed(address to, uint256 amount);
    event UpdateTaxPercentage(uint256 percentage);
    event ConfigurePair(address pair, bool isPair);
    event ConfigureBot(address pair, bool isBot);
    event UpdateTaxWallet(address wallet);
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _taxWallet) public initializer {
        if (_admin == address(0) || _taxWallet == address(0))
            revert AddressNotNull();

        __ERC20_init("UAP", "UAP");
        __ERC20Burnable_init();
        __Ownable_init();
        transferOwnership(_admin);
        taxWallet = _taxWallet;
        sellTaxPercentage = 10;
    }

    function setup() external {
        //totalSupply is 420000000000 * 1e18;
        //this function only available on Ethereum mainnet
        // if(block.chainid != 1) revert NotAllowedInThisBlockchain();
        if (isInitialized) revert AlreadyInitialized();

        initializeTime = block.timestamp;
        gameReward = 210_000_000_000 * 1e18;
        liquidityTrading = 105_000_000_000 * 1e18;
        teamAdvisor = 21_000_000_000 * 1e18;
        ecosystemGrowth = 63_000_000_000 * 1e18;
        developmentFund = 21_000_000_000 * 1e18;

        adminWallet = 0xbCD418c12CD9910DD5B33b1F8eE47eCc562732fC;
        liquidityWallet = 0xE73dEa1340AeCa4AA979438c9950dDfB28DE626C;
        teamAdvisorWallet = 0x20A2968eEfc8c89Aa7b2bb14bf76e22146D6B876;
        _distributeToken();
        _reserveToken();

        isInitialized = true;
    }
    /**
     * only called once when deploy the contract
     */
    function _distributeToken() private {
        //manually transfer tokens to admin for beam alloc
        _mint(adminWallet, gameReward);
        _mint(liquidityWallet, liquidityTrading);
        _mint(adminWallet, ecosystemGrowth);
        _mint(adminWallet, developmentFund);
    }

    function _reserveToken() private {
        //manually transfer tokens to admin for beam alloc
        _mint(address(this), teamAdvisor);
    }

    function updateTax(uint256 _sellTaxPercentage) external onlyOwner {
        if (_sellTaxPercentage > 100)
            revert CannotUpdateTax(_sellTaxPercentage);
        sellTaxPercentage = _sellTaxPercentage;
        emit UpdateTaxPercentage(_sellTaxPercentage);
    }

    function configurePairs(address _pair, bool _isPair) external onlyOwner {
        if (_pair == address(0)) revert CannotNull();
        isPair[_pair] = _isPair;

        emit ConfigurePair(_pair, _isPair);
    }

    function configureBot(address bot, bool isBot) external onlyOwner {
        bots[bot] = isBot;

        emit ConfigureBot(bot, isBot);
    }

    function updateTaxWallet(address _taxWallet) external onlyOwner {
        if (_taxWallet == address(0)) revert AddressNotNull();
        taxWallet = _taxWallet;

        emit UpdateTaxWallet(_taxWallet);
    }

    /**
     * @dev claim all avilable unlocked token to admin wallet
     */
    function claimUnlockedTeamAdvisorTokenAmount() external onlyOwner {
        uint256 unlockedAmount = getUnlockedTeamAdvisorTokenAmount();
        uint256 amountToClaim = unlockedAmount -
            alreadyClaimedTeamAdvisorTokenAmount;
        this.transfer(adminWallet, amountToClaim);
        alreadyClaimedTeamAdvisorTokenAmount += amountToClaim;
        emit TeamAdvisorTokenClaimed(adminWallet, amountToClaim);
    }

    /**READ function */
    /**
     * @dev return unlocked team advisor token amount. it is unlocked each quartely for 2 years
     *      Total unlock amount 21B, each quartely unlock amount 2.625B
     */
    function getUnlockedTeamAdvisorTokenAmount() public view returns (uint256) {
        //1 quarter in second (365 / 4) * 24 * 3600 = 7884000
        uint256 elapsedQuarter = (block.timestamp - initializeTime) / 7884000;
        //quarter unlock amount 21B / 8(2year) =  2.625B
        uint256 unlockedAmount = 2_625_000_000 * 1e18 * elapsedQuarter;
        return unlockedAmount > teamAdvisor ? teamAdvisor : unlockedAmount;
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 taxAmount;
        if (from != owner() && to != owner()) {
            require(
                !bots[from] && !bots[to],
                "Malicious Bot Transfer detected"
            );
            if (isPair[to] && from != address(this)) {
                taxAmount = (amount * sellTaxPercentage) / 100;
            }
        }
        if (taxAmount == 0) {
            super._transfer(from, to, amount);
        } else {
            super._transfer(from, to, amount - taxAmount);
            super._transfer(from, taxWallet, taxAmount);
            emit TaxTransfered(from, taxWallet, taxAmount);
        }
    }
}
