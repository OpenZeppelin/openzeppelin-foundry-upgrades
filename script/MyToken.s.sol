// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {MyTokenV2} from "../src/MyTokenV2.sol";

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";

contract MyTokenScript is Script {
  function setUp() public {}

  function run() public {
    vm.startBroadcast();

    address proxy = address(Upgrades.deployTransparentProxy(type(MyToken).creationCode, msg.sender, abi.encodeCall(MyToken.initialize, ("hello", msg.sender))));
    Upgrades.upgradeProxy(proxy, type(MyTokenV2).creationCode, msg.sender, abi.encodeCall(MyTokenV2.resetGreeting, ()));

    address beacon = address(Upgrades.deployBeacon(type(MyToken).creationCode, msg.sender));
    Upgrades.upgradeBeacon(beacon, type(MyTokenV2).creationCode, msg.sender);    

    vm.stopBroadcast();
  }
}




