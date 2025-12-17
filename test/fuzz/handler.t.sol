
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; //is goona handlethe way we call function so we dont waste runs


import {DeployDSC} from "script/DeployDSC.s.sol";

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DecentralisedStableCoin} from "src/Decentrialsed.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/helperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";


contract Handler is Test{

DSCEngine dscengine;
DecentralisedStableCoin dsc;
address weth;
address wbtc;
uint256 MAX_DEPOSIT_SIZE = type(uint96).max;




constructor(DSCEngine _dscengine, DecentralisedStableCoin _dsc,address _weth, address _wbtc){
    dscengine = _dscengine;
    dsc = _dsc;

    weth = _weth;
    console.log('weth address',weth);
    wbtc = _wbtc;
}





function depositCollateral(uint256 collatralSeed,uint256 amountCollateral) external{

address collateral = _getCollateralFromSeed(collatralSeed);
// this line  means from which number will it start calling the fn with and which to stop;

// the bound is a build in function we can we to specify where it will start and end


amountCollateral = bound(amountCollateral, 1,  MAX_DEPOSIT_SIZE );


vm.startPrank(msg.sender);
ERC20Mock(collateral).mint(msg.sender,amountCollateral);
ERC20Mock(collateral).approve(address(dscengine),amountCollateral);


dscengine.depositColletral(collateral,amountCollateral);

vm.stopPrank();


}





function redeemCollateral(uint256 collatralSeed,uint256 amountCollateral) external{

address collateralAdd = _getCollateralFromSeed(collatralSeed);
uint256 userDepositedCollateralRedeem = dscengine.getCollateralDepositedTokenAmount(msg.sender,collateralAdd);

console.log(userDepositedCollateralRedeem,'total deposited');
console.log(msg.sender,'sender address');

//vm.assume( userDepositedCollateralRedeem > 0);

// if(userDepositedCollateralRedeem == 0){
//     userDepositedCollateralRedeem = 2;
// }



amountCollateral = bound(amountCollateral, 0,  userDepositedCollateralRedeem );


console.log(userDepositedCollateralRedeem,'total deposited');
console.log(amountCollateral,'amount to redeem');

if(amountCollateral == 0) return;


dscengine.redeemColletral(msg.sender,collateralAdd, amountCollateral);




}

















function _getCollateralFromSeed(uint256 collateralSeed) private view returns(address){

if(collateralSeed % 2 == 0){
    return weth;
}else{
    return wbtc;

}



}







}