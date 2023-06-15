// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapUp is ERC20Capped, Ownable{
    constructor() ERC20("SwapUp.Trade","SWPUP") ERC20Capped(1000000000000*10**18) {}

    function mint(address to,uint256 amount)public onlyOwner {
        _mint(to,amount*10**18);
    }

    function mintToTeam(address dev, address marketing)public onlyOwner{
        uint amount = 1000000000000*0.05; //5% of total tokens
        _mint(dev,amount*10**18);
        _mint(marketing,amount*10**18);
    }

    function mintToPool(address poolContract)public onlyOwner {
        uint amount = 1000000000000*0.6; //60% of total tokens
        _mint(poolContract,amount*10**18);
    }

    function mintToRewards(address rewardsContract)public onlyOwner {
        uint amount = 1000000000000*0.3; //30% of total tokens
        _mint(rewardsContract,amount*10**18);
    }

    function burn(address account,uint amount)public onlyOwner {
        _burn(account,amount*10**18);
    }

    function GetBalance(address add) public view returns(uint) {
        return balanceOf(add)/(10**18);
    }
}
