//Have our invariant aka properties that should always hold

//  what are our invariants

// 1. The total suplly of DSC should be less than the totla value of collateral


// 2. Getter view function should never revert <-- evergreen invariant

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployDSC} from "script/DeployDSC.s.sol";

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DecentralisedStableCoin} from "src/Decentrialsed.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/helperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "test/fuzz/handler.t.sol";


contract InvariantsTest is  StdInvariant, Test{

    DeployDSC deployer;
DSCEngine dscengine;
DecentralisedStableCoin dsc;
HelperConfig.NetworkConfig config;
address ethUsdPriceFeed;
    address weth;
    address btcUsdPriceFeed;
    address wbtc;
    Handler handler;


    function setUp() external {
        deployer = new DeployDSC();
        (dscengine, dsc, config) = deployer.run();
         ethUsdPriceFeed = config.wethUsdPriceFeed;
        weth = config.weth;
wbtc= config.wbtc;
btcUsdPriceFeed = config.wbtcUsdPriceFeed;

//targetContract(address(dscengine));

// now it is going to the function in handler with diffren val
handler = new Handler(dscengine,dsc,weth,wbtc);

targetContract(address(handler));


//Hey dont call redeem collateral unless thier is collateral to



    }


function invariants_protocolMustHaveMoreValueThanTotal() external view{
// get the value of all the collateral in the protocol
//compare it to all the dbt dsc minted


uint256 totalSupply = dsc.totalSupply();



uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscengine));
uint256 totalBtcDeposited = IERC20(wbtc).balanceOf(address(dscengine));

console.log('Total Supply',totalSupply);
console.log('Total Weth Deposited',totalWethDeposited);

uint256 totalWethValue = dscengine.getUsdValue(weth, totalWethDeposited);
uint256 totalBtcValue = dscengine.getUsdValue(wbtc, totalBtcDeposited);

console.log('Weth value',totalWethValue, weth);
console.log('Btc value',totalBtcValue,weth);


assert( totalWethValue + totalBtcValue >= totalSupply);




}

   


}