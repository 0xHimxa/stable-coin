//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DecentralisedStableCoin} from "./Decentrialsed.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    AggregatorV3Interface
} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

//"@chainlink/contracts=lib/chainlink-brownie-contracts/contracts/",

/***
 *@title DecentralisedStableCoin
 *@author Himxa
 *@Collecteral: Exogenous (ETH & BTC)
 *the system is designd to be as minimal as posible, and have the tokens maintain a 1token == 1 USD pegged
 * Minting: Algorithmic stable
 * Relative Stability: Pegged to USD
 * it similar to DAI if DAI had not govenece,no fees and was only backed by WETH and WBTC
 *
 *@notice this contract is the core of the DSC system. it handle the logic for minting
 * and redeeming DSC, as well as depositing & withdrawing collecteral.
 * @notice this contract is Very loosely based on the MakerDao (DAI) system.
 */

contract DSCEngine {
    /////////////////////////////
    //    ERRORS         //
    /////////////////////////////

    error DSCEngine__MustBeMoreThanZero();
    error DSCEngine__BurnAmountExeedBanlance();
    error DSCEngine__NotToZeroAddress();
    error DSCEngine__TokenAdressesAndPriceFeedAddressMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__HealthFactorBroken(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOK();
    error DSCEngine__HealthFactorNotImporived();

    /////////////////////////////
    //  State Variables       //
    /////////////////////////////
    mapping(address token => address pricefeed) private s_priceFeed;
    mapping(address user => mapping(address token => uint256 amount))
        private s_collectralDeposited;
    mapping(address user => uint256 amount) private s_dscMinted;
    DecentralisedStableCoin private s_dsc;
    address[] private s_collateralTokens;
    uint256 private constant ADDTIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // mean we need to have 2times the amount minted as collectral
    uint256 private constant LIQUIDATION_PRICISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATON_BONUS = 10;

    /////////////////////////////
    //  Events      //
    /////////////////////////////

    event CollectralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );
    event CollateralRedeemed(
        address indexed redeemdFrom,
        address indexed redeemedTo,
        address indexed token,

        uint256  amount
    );
    /////////////////////////////
    // Modifiers          //
    /////////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__MustBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeed[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    /////////////////////////////
    // Functions          //
    /////////////////////////////

    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAdress
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAdressesAndPriceFeedAddressMustBeSameLength();
        }

        for (uint256 i; i < tokenAddresses.length; i++) {
            s_priceFeed[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        s_dsc = DecentralisedStableCoin(dscAdress);
    }

    /////////////////////////////
    // Exteranl Functions          //
    /////////////////////////////
    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     * @param amountDscToMint: The amount of DSC you want to mint
     * @notice This function will deposit your collateral and mint DSC in one transaction
     */

    function depositCollecteralAndMintDsc(
        address tokenCollecteralAddress,
        uint256 amountColleteral,
        uint256 amountDscToMint
    ) external {
        depositColletral(tokenCollecteralAddress, amountColleteral);
        mintDsc(amountDscToMint);
    }

    // check more about thi smodifier, nonReentrant: he said it protect from vonu ask ai and also check the file it
    //imported from
    // didnot add it tho

    /**
     *@notice follows CEI
     */

    function depositColletral(
        address tokenCollecteralAddress,
        uint256 amountColleteral
    )
        public
        moreThanZero(amountColleteral)
        isAllowedToken(tokenCollecteralAddress)
    {
        s_collectralDeposited[msg.sender][
            tokenCollecteralAddress
        ] += amountColleteral;
        // s_dsc.mint(msg.sender, amountColleteral);
        emit CollectralDeposited(
            msg.sender,
            tokenCollecteralAddress,
            amountColleteral
        );

        // so we are user WBTC and WETH they  are all ERC20 so we import to intract with them

        bool success = IERC20(tokenCollecteralAddress).transferFrom(
            msg.sender,
            address(this),
            amountColleteral
        );

        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're withdrawing
     * @param amountCollateral: The amount of collateral you're withdrawing
     * @param amountDscToBurn: The amount of DSC you want to burn
     * @notice This function will withdraw your collateral and burn DSC in one transaction
     */

    function redeemCollecteralForDsc(
        address tokenCollecteralAddress,
        uint256 amount
    ) external {
        burnDsc(amount);

        redeemColletral(tokenCollecteralAddress, amount);
        //redeemcollertral already checks health factor
    }




    function redeemColletral(
        address tokenCollecteralAddress,
        uint256 amount
    ) public moreThanZero(amount) {
       _redeemCollateral(msg.sender,msg.sender,tokenCollecteralAddress,amount);
        _revertHealFactorBroken(msg.sender);
    }

    /**
     *@notice follows CEI
     */





    function mintDsc(
        uint256 amountDscToMint
    ) public moreThanZero(amountDscToMint) {
        s_dscMinted[msg.sender] += amountDscToMint;

        //if they minted to much ($150 DSC, $100 ETH);

        _revertHealFactorBroken(msg.sender);
        bool minted = s_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc(uint256 amount) public moreThanZero(amount) {
    _burnDsc(amount, msg.sender, msg.sender);
        _revertHealFactorBroken(msg.sender); // it will prob never reach this line
        //emit DSCBurned(msg.sender, amount);
    }

    // threshold to let say 150%
    //$100 eth -> $75
    // you get $50 dai
    // you colecteral drop to $74
    //some one in the system will pay back your minted DSC, the can have the collecteral for
    // discont

    function liquidate(
        address colletral,
        address user,
        uint256 debtToCover
    ) external moreThanZero(debtToCover) {
        //need to check  the health factor of the user
        uint256 startingUserHealthFactor = _healthFactore(user);

        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOK();
        }

        //we want to burn  thier DSC "debt"
        // And take thier Collatral
        //Bad User: $140 eth, $100 DSC= they are undercoletralzed
        // $debt of DSC == $?? ETh;

        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(
            colletral,
            debtToCover
        );

        //And give them 10% bounus
        //so we are giving the liquidator $110 of weth for $100 DSC

        uint256 bonusCollateral = (tokenAmountFromDebtCovered *
            LIQUIDATON_BONUS) / LIQUIDATION_PRICISION;

        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered +
            bonusCollateral;


            _redeemCollateral(user, msg.sender, colletral, totalCollateralToRedeem);
  
  _burnDsc(debtToCover, user, msg.sender);
  uint256 endingUserHealthFactor = _healthFactore(user);

if(endingUserHealthFactor < MIN_HEALTH_FACTOR){

revert DSCEngine__HealthFactorNotImporived();

}



  
    }




    function getHealthFactor() external view {}

    /////////////////////////////
    // Private and Internal Functions       //
    /////////////////////////////



/**
*@dev low-level internal function, do not call unless the function calling it is
* checking for health factor
 */



function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address  dscFrom) private{
    s_dscMinted[onBehalfOf] -= amountDscToBurn;
        // with this alnoe it will work, just for incase that why we do it the other way

        // s_dsc.burn(msg.sender, amount);

        bool success = s_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);

        if (!success) {
            revert DSCEngine__TransferFailed();
        }

        s_dsc.burn(amountDscToBurn);   
}




function _redeemCollateral(address from, address to,address tokenCollecteralAddress, uint256 amountCollateral) private{


 s_collectralDeposited[from][tokenCollecteralAddress] -= amountCollateral;
        emit CollateralRedeemed(from,to, tokenCollecteralAddress, amountCollateral);

        bool success = IERC20(tokenCollecteralAddress).transfer(
            to,
            amountCollateral
        );

        if (!success) {
            revert DSCEngine__TransferFailed();
        }





}












    function _getAccountInformation(
        address user
    ) private view returns (uint256 totalMinted, uint256 collectralValueInUsd) {
        totalMinted = s_dscMinted[user];
        collectralValueInUsd = getAccountCollateralValueInUsd(user);
    }

    /**
     *@notice follows CEI
     * Returns how close  to liquidation a user is
     *if it goes below threshold the user get liquidated */

    function _healthFactore(address user) private view returns (uint256) {
        //total DSC minted
        //total collectral value
        // colletral val have to be alway > than minted value

        (
            uint256 totalMinted,
            uint256 collectralValueInUsd
        ) = _getAccountInformation(user);
        uint256 collectralAdjustedForThreshold = (collectralValueInUsd *
            LIQUIDATION_THRESHOLD) / LIQUIDATION_PRICISION;

        //1000 eth * 50 = 50000 / 100 = 500 if drop below it liquidate them

        //500/100 > 1
        //that thier health factor

        return (collectralAdjustedForThreshold * PRECISION) / totalMinted;
    }

    //1. check do they have enough colleteral
    //2. Revert if they Dont
    function _revertHealFactorBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactore(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorBroken(userHealthFactor);
        }
    }

    /////////////////////////////////////////
    //   Public & Exteranl View Function //
    //////////////////////////////////////

    function getTokenAmountFromUsd(
        address token,
        uint256 usdAmountInWei
    ) public view returns (uint256 amount) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            s_priceFeed[token]
        );
        (, int256 price, , , ) = pricefeed.latestRoundData();
        //($10e18 * 1e18) / ($2000e8 * 1e10)
        return
            (usdAmountInWei * PRECISION) /
            (uint256(price) * ADDTIONAL_FEED_PRECISION);
    }

    function getAccountCollateralValueInUsd(
        address user
    ) public view returns (uint256 totalCollateralValueInUsd) {
        //llop throug each colleceral token,get the amount they have deposited,and map it to
        //the price, to get the token use value

        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collectralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
    }

    function getUsdValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            s_priceFeed[token]
        );
        (, int256 price, , , ) = pricefeed.latestRoundData();

        return
            ((uint256(price) * ADDTIONAL_FEED_PRECISION) * amount) / PRECISION;
    }



    function getAccountInfomation(address user) external view returns(uint256 totalMinted, uint256 collectralValueIn){

(totalMinted, collectralValueIn) = _getAccountInformation(user);


return (totalMinted, collectralValueIn);
    }
}
