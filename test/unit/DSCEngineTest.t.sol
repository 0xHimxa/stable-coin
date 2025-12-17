//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployDSC} from "script/DeployDSC.s.sol";

import {Test, console} from "forge-std/Test.sol";
import {DecentralisedStableCoin} from "src/Decentrialsed.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/helperConfig.s.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DecentralisedStableCoin dsc;
    DSCEngine dscengine;
    HelperConfig.NetworkConfig config;
    address ethUsdPriceFeed;
    address weth;
    address btcUsdPriceFeed;
    address wbtc;

        uint256 private constant ADDTIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // mean we need to have 2times the amount minted as collectral
    uint256 private constant LIQUIDATION_PRICISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATON_BONUS = 10;


    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 140 ether;

    function setUp() external {
        DeployDSC deployer = new DeployDSC();
        (dscengine, dsc, config) = deployer.run();
        ethUsdPriceFeed = config.wethUsdPriceFeed;
        weth = config.weth;
wbtc= config.wbtc;
btcUsdPriceFeed = config.wbtcUsdPriceFeed;


        //vm.dea(USER,20 ether);

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }



    ///////////////////////
    // Constructor Tests       //
    ///////////////////////



address[] public tokenAddresses;
address[] public priceFeedAddresses; 




function testRevertIfTokenLengthDoestMatchPriceFeedLength() external {

tokenAddresses.push(weth);
priceFeedAddresses.push(ethUsdPriceFeed);
priceFeedAddresses.push(btcUsdPriceFeed);

vm.expectRevert(DSCEngine.DSCEngine__TokenAdressesAndPriceFeedAddressMustBeSameLength.selector);

new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));



}


////////////////////////
 // Modifiers        //
 //////////////////////

modifier depositCollateral(){

vm.startPrank(USER);
ERC20Mock(weth).approve(address(dscengine), AMOUNT_COLLATERAL);
dscengine.depositColletral(weth, AMOUNT_COLLATERAL);
vm.stopPrank();

_;

}

modifier mintDsc(){

vm.startPrank(USER);
dscengine.mintDsc(5 ether);
vm.stopPrank();

_;

}







    ///////////////////////
    // State Variable Tests       //
    ///////////////////////


function testGetPriceFeedAddressFromTokenAddress() external{

assertEq(ethUsdPriceFeed,dscengine.getPriceFeedAdressFromTokenAddress(weth));
assertEq(btcUsdPriceFeed,dscengine.getPriceFeedAdressFromTokenAddress(wbtc));


}


function testGetCollateralDepositedAmountByUser() external depositCollateral{

assertEq(AMOUNT_COLLATERAL,dscengine.getCollateralDepositedTokenAmount(USER,weth));
}



function testGetMintedDscAmountByUser() external depositCollateral mintDsc{




assertEq(5 ether,dscengine.getUserMintedDscAmount(USER));


}


function testGetCollateralTokenAddress() external{

assertEq(weth,dscengine.getCollateralTokenAddress(0));
assertEq(wbtc,dscengine.getCollateralTokenAddress(1));

}



function testAddtionalPrecisionFee() external view{

assertEq(ADDTIONAL_FEED_PRECISION,dscengine.getAdditionalFeedPrecision());

}


function testPrecision() external view{

assertEq(PRECISION,dscengine.getPrecision());

}


function testLiquidationThreshold() external view{

assertEq(LIQUIDATION_THRESHOLD,dscengine.getLiquidationThreshold());

}


function testLiquidationPrecision() external view{

assertEq(LIQUIDATION_PRICISION,dscengine.getLiquidationPrecision());

}


function testMinHealthFactor() external view{

assertEq(MIN_HEALTH_FACTOR,dscengine.getMinHealthFactor());

}


function testLiquidationBonus() external view{

assertEq(LIQUIDATON_BONUS,dscengine.getLiquidationBonus());

}





//////////////////////////

  // Redeem Functions Tests //
  //////////////////////////


function testRedeemCollateral() external depositCollateral{

vm.prank(USER);
dscengine.redeemColletral(USER,weth, AMOUNT_COLLATERAL);


assertEq(ERC20Mock(weth).balanceOf(USER)
, STARTING_ERC20_BALANCE);




}



function testRedeemCollatranlFailedHealthFactorBroken() external depositCollateral mintDsc{


vm.prank(USER);

vm.expectRevert(DSCEngine.DSCEngine__HealthFactorBroken.selector);
dscengine.redeemColletral(USER,weth, AMOUNT_COLLATERAL);


}


function testRedeepCollateralForDsc() external depositCollateral mintDsc{

vm.startPrank(USER);
dsc.approve(address(dscengine), 5 ether);
//this line deemcollatral and burn the dsc
dscengine.redeemCollecteralForDsc(USER,weth, 5 ether);
vm.stopPrank();

vm.prank(USER);






// this line redeem our remaining collateral in the contract
dscengine.redeemColletral(USER,weth, 5 ether);


assertEq(ERC20Mock(weth).balanceOf(USER)
, STARTING_ERC20_BALANCE);

assertEq(dsc.balanceOf(USER), 0);



}



 












    ///////////////////////
    //  Price Tests       //
    ///////////////////////

    function testGetUsdValue() external {
        uint256 ethAmount = 15e18;
        //15e18 * 2000/eth = 30000e18
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dscengine.getUsdValue(weth, ethAmount);
        console.log(actualUsd);
        assert(actualUsd == expectedUsd);
    }




function testGetTokenAmountFromUsd() external{

  uint256 usdAmount = 100 ether;
  uint256 expectedAmount = 0.05 ether;
  uint256 actualAmount = dscengine.getTokenAmountFromUsd(weth, usdAmount);
  assertEq(actualAmount,expectedAmount);


}







    ///////////////////////
    // DepositCollateral Tests //
    ///////////////////////

    function testRevertsIfCollateralZero() external {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscengine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__MustBeMoreThanZero.selector);

        dscengine.depositColletral(weth, 0);
        vm.stopPrank();
    }




function testRevertWithUnapprovedCollateral() external {

ERC20Mock newToken = new ERC20Mock();

vm.prank(USER);
vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
dscengine.depositColletral(address(newToken), AMOUNT_COLLATERAL);



}





function testCanDepositCollateralAndGetInfo() external depositCollateral{

(uint256 totalMinted, uint256 collectralValueInUsd) = dscengine.getAccountInfomation(USER);


uint256 expectedTotalMinted = 0;
uint256 expectedDepositAmount = dscengine.getTokenAmountFromUsd(weth, collectralValueInUsd);


assertEq(totalMinted, expectedTotalMinted);
assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);



}


}