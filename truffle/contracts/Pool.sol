// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Pool {
  address constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // uniswap router v2 contract address
  address constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // uniswap fatory contract address
  IUniswapV2Router02 router;
  IUniswapV2Factory factory;
  address constant SWPUP = 0x49686479d16105c278a766f3Abe24d3D50300a71; // swapup token address
  address constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //weth address on goerli
  mapping(address=>uint) timestamps; // for storing timestamps to implement locking functionality
  mapping(address=>uint) liquidities; // for storing liquidity amounts provided by each user

  event Log(string message, uint val);

  constructor() {
    router = IUniswapV2Router02(ROUTER); // uniswap router v2
    factory = IUniswapV2Factory(FACTORY); //uniswap factory
  }

  function addLiquidity(
    uint SwpupDesired,
    uint SwpupMin, // min acceptable amount of swpup tokens which may be added to the pool
    uint WethDesired,
    uint WethMin // min acceptable amount of weth tokens which may be added to the pool
  ) external {
    IUniswapV2ERC20(SWPUP).approve(ROUTER, SwpupDesired); // approving the router to transfer SWPUP to be provided for liquidity on our behalf
    IUniswapV2ERC20(WETH).approve(ROUTER, WethDesired); // approving the router to transfer WETH to be provided for liquidity on our behalf
    (uint AmountSwpup, uint AmountWeth, uint liquidity) = // amounts of swpup and weth added to the pool and the liquidity tokens gained in return
      router.addLiquidity( // adding liquidity using the uniswap router, this method will first create a pool if it doesn't exist
        SWPUP, // swpup token address
        WETH, // weth token address
        SwpupDesired,
        WethDesired,
        SwpupMin,
        WethMin,
        address(this),
        block.timestamp + 10 minutes // deadline for executing the liquidty txn, arbitrarily set to 10 mins from inititiation of txn
      );
    timestamps[msg.sender] = block.timestamp + 2 minutes; // timestamp for liquidity locking, set to 2 minutes for testing will be changed to 180 days (6 months) in prod
    if (SwpupDesired - AmountSwpup > 0) { // checking if any swpup was returned by uniswap to mainatin the weth to swpup ratio
      IUniswapV2ERC20(SWPUP).transfer(msg.sender, SwpupDesired - AmountSwpup); // transferring any swpup returned back to user
    }
    if (WethDesired - AmountWeth > 0) { // checking if any swpup was returned by uniswap to mainatin the weth to weth ratio
      IUniswapV2ERC20(WETH).transfer(msg.sender, WethDesired - AmountWeth); // transferring any weth returned back to user
    }
    liquidities[msg.sender] = liquidity; //storing liquidity supplied by the user
    emit Log("AmountSwpup", AmountSwpup);
    emit Log("AmountWeth", AmountWeth);
    emit Log("liquidity", liquidity);
  }

  function removeLiquidity() external {
    require(timestamps[msg.sender] < block.timestamp, "Liquidity Locked!"); // checking if the liquidity lock deadline has elapsed or not
    address pair = factory.getPair(SWPUP, WETH); // getting address of the swpup/weth trading pair liquidity tokens
    uint liquidity = liquidities[msg.sender]; // total amount of liquidity tokens gained from the liquidity provided by the user
    IUniswapV2ERC20(pair).approve(ROUTER, liquidity); // approving the uniswap router to transfer liquidity tokens on our behalf
    (uint AmountSwpup, uint AmountWeth) = // amounts of weth and swpup tokens withdrawn form the pool
      router.removeLiquidity( // removing the user's liquidity using uniswap router v2
        SWPUP, // swpup token address
        WETH, // weth token address
        liquidity, // amount of liquidity which will be burnt to get back the user's liquidity
        1, // min acceptable amount of swpup tokens which may be added to the pool set to 1x10^-18 for testing
        1, // min acceptable amount of weth tokens which may be added to the pool set to 1x10^-18 for testing
        address(this),
        block.timestamp + 10 minutes // deadline for executing the liquidty txn, arbitrarily set to 10 mins from inititiation of txn
      );
    IUniswapV2ERC20(SWPUP).transfer(msg.sender, AmountSwpup); // transferring swpup tokens back to user
    IUniswapV2ERC20(WETH).transfer(msg.sender, AmountWeth); // transferring weth tokens back to user
    emit Log("AmountSwpup", AmountSwpup);
    emit Log("AmountWeth", AmountWeth);
  }

  function swapSwpupForWeth(
    uint AmountIn
  ) external {
    IUniswapV2ERC20(SWPUP).approve(ROUTER, AmountIn);
    address[] memory path = new address[](2);
    path[0] = SWPUP;
    path[1] = WETH;
    router.swapExactTokensForETH(
      AmountIn, 1, path, msg.sender, block.timestamp + 10 minutes
    );
  }

  function swapWethForSwpup(
    uint AmountIn
  ) external {
    IUniswapV2ERC20(WETH).approve(ROUTER, AmountIn);
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = SWPUP;
    router.swapExactTokensForTokens(
      AmountIn, 1, path, msg.sender, block.timestamp + 10 minutes
    );
  }
}
