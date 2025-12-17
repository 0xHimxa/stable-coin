//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {
    AggregatorV3Interface
} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/***
*@title OracleLib
*@author Himxa
*@notice this library is used to check the cahinlink oracle for stale data
* if a price is stale, the function will revert, and render the DSCEngine unusabel - this  is by design

* we want the DSCengine to freeze if price is stale
*
* if the chainlink nextworks explodes and you have a lot of money locked in th protocol.... to bad
*/

library OracleLib {
    error OracleLib__PriceIsStale();

    uint256 private constant TIMEOUT = 3 hours;

    function staleCheckLatestRoundData(
        AggregatorV3Interface priceFeed
    ) public view returns (uint80, int256, uint256, uint256, uint80) {

(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();

uint256 secondsSince = block.timestamp - updatedAt;

if (secondsSince > TIMEOUT) {
    revert OracleLib__PriceIsStale();
}

return (roundId, answer, startedAt, updatedAt, answeredInRound);


    }
}
