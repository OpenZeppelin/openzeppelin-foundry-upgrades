// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {Greeter} from "./contracts/Greeter.sol";
import {GreeterProxiable} from "./contracts/GreeterProxiable.sol";
import {GreeterV2} from "./contracts/GreeterV2.sol";
import {GreeterV2Proxiable} from "./contracts/GreeterV2Proxiable.sol";

import {Defender} from "openzeppelin-foundry-upgrades/Defender.sol";
import {Utils} from "openzeppelin-foundry-upgrades/internal/Utils.sol";
import {console} from "forge-std/console.sol";

contract UpgradesScript is Script {
    function setUp() public {}

    function run() public {
        (string memory shortName, string memory contractPath) = Utils.getContractNameComponents("out", "Foo.sol:Greeter");
        console.log("shortName ", shortName);
        console.log("contractPath ", contractPath);
    }
}
