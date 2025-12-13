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
   uint256 private constant MIN_HEALTH_FACTOR = 1;

    /////////////////////////////
    //  Events      //
    /////////////////////////////

    event CollectralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
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

    function depositCollecteralAndMintDsc() external {}

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
        external
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

    function redeemCollecteralForDsc() external {}
    function redeemColletral() external {}

    /**
     *@notice follows CEI
     */

    function mintDsc(
        uint256 amountDscToMint
    ) external moreThanZero(amountDscToMint) {
        s_dscMinted[msg.sender] += amountDscToMint;

        //if they minted to much ($150 DSC, $100 ETH);

        _revertHealFactorBroken(msg.sender);

        
    }

    function burnDsc() external {}

    // threshold to let say 150%
    //$100 eth -> $75
    // you get $50 dai
    // you colecteral drop to $74
    //some one in the system will pay back your minted DSC, the can have the collecteral for
    // discont

    function liquidate() external {}
    function getHealthFactor() external view {}

    /////////////////////////////
    // Private and Internal Functions       //
    /////////////////////////////

    function _getAccountInformation(
        address user
    ) private view returns (uint256 totalMinted, uint256 collectralValueInUsd) {
        uint256 totalMinted = s_dscMinted[user];
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
uint256 collectralAdjustedForThreshold = (collectralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRICISION;

//1000 eth * 50 = 50000 / 100 = 500 if drop below it liquidate them



//500/100 > 1
//that thier health factor

return(collectralAdjustedForThreshold * PRECISION)/totalMinted;


    }

//1. check do they have enough colleteral
        //2. Revert if they Dont
    function _revertHealFactorBroken(address user) internal view {
        
    uint256 userHealthFactor = _healthFactore(user);
    if(userHealthFactor < MIN_HEALTH_FACTOR){
        revert DSCEngine__HealthFactorBroken(userHealthFactor);

    }

    
    }

    /////////////////////////////////////////
    //   Public & Exteranl View Function //
    //////////////////////////////////////
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

        return ((uint256(price )* ADDTIONAL_FEED_PRECISION) * amount) / PRECISION;
    }
}
