
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; //is goona handlethe way we call function so we dont waste runs


import {DeployDSC} from "script/DeployDSC.s.sol";

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DecentralisedStableCoin} from "src/Decentrialsed.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/helperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
