//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { DeployDSC} from 'script/DeployDSC.s.sol';

import {Test} from 'forge-std/Test.sol';
import {DecentralisedStableCoin} from "src/Decentrialsed.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/helperConfig.s.sol";




contract DSCEngineTest is Test{
 DecentralisedStableCoin dsc;
 DSCEngine dscengine;
HelperConfig.NetworkConfig config;
address ethUsdPriceFeed;
address weth;

function setUp() external{

DeployDSC deployer = new DeployDSC();
(dscengine,dsc,config) = deployer.run();
ethUsdPriceFeed = config.wethUsdPriceFeed;
weth = config.weth;




}





///////////////////////
//  Price Tests       //
///////////////////////


function testGetUsdValue()external{

uint256 ethAmount = 15e18;
//15e18 * 2000/eth = 30000e18
uint256 expectedUsd = 30000e18;
uint256 actualUsd = dscengine.getUsdValue(weth,ethAmount);

assert(actualUsd == expectedUsd);

}










}





