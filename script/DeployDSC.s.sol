//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {DecentralisedStableCoin} from "src/Decentrialsed.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/helperConfig.s.sol";

contract DeployDSC is Script{
 address[] public tokenAdresses;
 address[] public priceFeedAddresses;

    function run() external returns(DSCEngine,DecentralisedStableCoin){
HelperConfig helperConfig = new HelperConfig();
HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
 tokenAdresses = [config.weth,config.wbtc];
 tokenAdresses = [config.weth,config.wbtc];
 priceFeedAddresses = [config.wethUsdPriceFeed,config.wbtcUsdPriceFeed];

    vm.startBroadcast();
    DecentralisedStableCoin dsc = new DecentralisedStableCoin();
    DSCEngine dscengine = new DSCEngine(tokenAdresses,priceFeedAddresses,address(dsc));
dsc.transferOwnership(address(dscengine));
    vm.stopBroadcast();

    return (dscengine,dsc);
    }
}