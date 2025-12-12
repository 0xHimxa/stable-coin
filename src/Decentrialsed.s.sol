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

// the owner able says only us can perform ceertain action 
contract DecentralisedStableCoin is ERC20Burnable,Ownable {

constructor()ERC20("Decentrailsed","DSC"){

}



}

