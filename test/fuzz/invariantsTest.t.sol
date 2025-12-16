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

contract InvariantsTest is  StdInvariant, Test{

    DeployDSC deployer;
DSCEngine dscengine;
DecentralisedStableCoin dsc;
HelperConfig.NetworkConfig config;

    function setUp() external {
        deployer = new DeployDSC();
        (dscengine, dsc, config) = deployer.run();


    }


   


}