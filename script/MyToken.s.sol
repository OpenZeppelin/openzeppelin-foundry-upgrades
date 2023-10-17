// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MyToken.sol";

contract MyTokenScript is Script {
  function setUp() public {}

  function run() public {
    vm.startBroadcast();
    MyToken instance = new MyToken();
    console.log("Contract deployed to %s", address(instance));
    vm.stopBroadcast();
  }
}
