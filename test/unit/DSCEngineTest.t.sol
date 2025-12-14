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
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() external {
        DeployDSC deployer = new DeployDSC();
        (dscengine, dsc, config) = deployer.run();
        ethUsdPriceFeed = config.wethUsdPriceFeed;
        weth = config.weth;

        //vm.dea(USER,20 ether);

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
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
}
