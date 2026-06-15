//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

     function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

     function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TraderPlatform is Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public token1;
    address public token2;
    constructor(address _router, address _token1, address _token2) {
        uniswapV2Router = IUniswapV2Router02(_router);
        token1 = _token1;
        token2 = _token2;
    }

    //create pair and add liquidity
    function setupTrade(uint256 token1Amount, uint256 token2Amount) external onlyOwner {
        IERC20(token1).approve(address(uniswapV2Router), token1Amount);
        IERC20(token2).approve(address(uniswapV2Router), token2Amount);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(token1, token2);
        uniswapV2Router.addLiquidity(token1, token2, token1Amount, token2Amount, 0, 0, owner(), block.timestamp + 5);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    //just add liquidity
    function addLiquidity(uint256 token1Amount, uint256 token2Amount) external onlyOwner {
        IERC20(token1).approve(address(uniswapV2Router), token1Amount);
        IERC20(token2).approve(address(uniswapV2Router), token2Amount);       
        uniswapV2Router.addLiquidity(token1, token2, token1Amount, token2Amount, 0, 0, owner(), block.timestamp + 5);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function swapExactTokensForTokens(uint256 token1Amount) external {
        IERC20(token1).transferFrom(msg.sender, address(this), token1Amount);
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;        
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(token1Amount, 0, path, msg.sender, block.timestamp + 5);        
    }

    function getBlockStamp() public view returns(uint256) {
        return block.timestamp;
    }
}
