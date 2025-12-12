//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {ERC20Burnable,ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";






/***
 *@title DecentralisedStableCoin
 *@author Himxa
 *@Collecteral: Exogenous (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 *
 *This is the contract meant to be governed by DSCEngine. This contract is just the ER2C020
 implementation
  
  */


  //click the inherinf file for more info

// the owner able says only the contract engine can perform ceertain action 
contract DecentralisedStableCoin is ERC20Burnable,Ownable {

error DecentralisedStableCoin__MustBeMoreThanZero();
error DecentralisedStableCoin__BurnAmountExeedBanlance();
error DecentralisedStableCoin__NotToZeroAddress();

constructor()ERC20("Decentrailseds","DSC") Ownable(msg.sender){}


function burn(uint256 _amount) public override onlyOwner{

uint256 balance = balanceOf(msg.sender);
if(_amount <= 0){
  revert DecentralisedStableCoin__MustBeMoreThanZero();
}

if(_amount > balance){
  revert DecentralisedStableCoin__BurnAmountExeedBanlance();
}

//the supper keyword means go to the frst parent and call burn with the val
super.burn(_amount);

}



function mint(address _to,uint256 _amount) external onlyOwner returns(bool){
if(_to == address(0)){
 revert  DecentralisedStableCoin__NotToZeroAddress();
 
}

if(_amount  <= 0){
  revert DecentralisedStableCoin__MustBeMoreThanZero();

}

_mint(_to,_amount);
return true;



}





}

