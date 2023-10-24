// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {MyToken} from "./contracts/MyToken.sol";
import {MyTokenV2} from "./contracts/MyTokenV2.sol";

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";

contract MyTokenScript is Script {
  function setUp() public {}

  function run() public {
    vm.startBroadcast();

    address proxy = address(Upgrades.deployTransparentProxy("MyToken.sol", msg.sender, abi.encodeCall(MyToken.initialize, ("hello", msg.sender))));
    Upgrades.upgradeProxy(proxy, "MyTokenV2.sol", abi.encodeCall(MyTokenV2.resetGreeting, ()));

    address beacon = address(Upgrades.deployBeacon("MyToken.sol", msg.sender));
    Upgrades.upgradeBeacon(beacon, "MyTokenV2.sol");

    vm.stopBroadcast();
  }
}
