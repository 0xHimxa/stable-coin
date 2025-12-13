//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {DecentralisedStableCoin} from "src/Decentrialsed.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {MockV3Aggregator} from "test/mocks/agg.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {

error HelperConfig_InvalidChainId();

    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerkey;
    }

    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 1000e8;
    uint256 public constant ANVIL_PIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;



constructor(){
  activeNetworkConfig = getSepoliaEthConfig();
}




function getConfigBYChainId(uint256 chainId) public returns (NetworkConfig memory){
 if(chainId ==  11155111){
    return activeNetworkConfig;
 }
 else if(chainId == 31337){
  return  getOrCreateAnvilNetworkConfig();

 }
 else{
    revert HelperConfig_InvalidChainId();
 }

}


function getConfig() public  returns(NetworkConfig memory){
    return getConfigBYChainId(block.chainid);
}







    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                //this two we been gooten from chain under sepo
                wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
                wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
                // this one patric deploy it,  do research
                weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
                wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
                deployerkey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getOrCreateAnvilNetworkConfig()
        public
        returns (NetworkConfig memory)
    {
        if (activeNetworkConfig.wbtcUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            ETH_USD_PRICE
        );
        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            BTC_USD_PRICE
        );


        // here we doploy our own weth,wbtc on anvill, that how patric did his firest deploy em
        ERC20Mock weth = new ERC20Mock();
        ERC20Mock wbtc = new ERC20Mock();

        vm.stopBroadcast();

return NetworkConfig({
    wethUsdPriceFeed: address(ethUsdPriceFeed),
    wbtcUsdPriceFeed: address(btcUsdPriceFeed),
    weth: address(weth),
    wbtc: address(wbtc),
    deployerkey: ANVIL_PIVATE_KEY

});



    }
}
