// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {Defender} from "openzeppelin-foundry-upgrades/Defender.sol";
import {console} from "forge-std/console.sol";

contract DefenderScript is Script {
    function setUp() public {}

    function run() public {
        string memory deployed = Defender.deployContract("MyContractFile.sol:MyContractName");
        console.log("Successfully deployed to address ", deployed);
    }
}
