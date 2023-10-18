// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

import {MyToken} from "../src/MyToken.sol";
import {MyTokenV2} from "../src/MyTokenV2.sol";
import {MyTokenProxiable} from "../src/MyTokenProxiable.sol";
import {MyTokenProxiableV2} from "../src/MyTokenProxiableV2.sol";

contract MyTokenTest is Test {

  function testUUPS() public {
    Proxy proxy = Upgrades.deployUUPSProxy("MyTokenProxiable.sol", abi.encodeCall(MyTokenProxiable.initialize, ("hello", msg.sender)));
    MyToken instance = MyToken(address(proxy));
    address implAddressV1 = Upgrades.getImplementationAddress(address(proxy));

    assertEq(instance.name(), "MyToken");
    assertEq(instance.greeting(), "hello");
    assertEq(instance.owner(), msg.sender);

    Upgrades.upgradeProxy(address(proxy), "MyTokenProxiableV2.sol", abi.encodeCall(MyTokenProxiableV2.resetGreeting, ()), msg.sender);
    address implAddressV2 = Upgrades.getImplementationAddress(address(proxy));

    assertEq(instance.greeting(), "resetted");
    assertFalse(implAddressV2 == implAddressV1);
  }

  function testTransparent() public {
    Proxy proxy = Upgrades.deployTransparentProxy("MyToken.sol", msg.sender, abi.encodeCall(MyToken.initialize, ("hello", msg.sender)));
    MyToken instance = MyToken(address(proxy));
    address implAddressV1 = Upgrades.getImplementationAddress(address(proxy));
    address adminAddress = Upgrades.getAdminAddress(address(proxy));

    assertFalse(adminAddress == address(0));

    assertEq(instance.name(), "MyToken");
    assertEq(instance.greeting(), "hello");
    assertEq(instance.owner(), msg.sender);

    Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol", abi.encodeCall(MyTokenV2.resetGreeting, ()), msg.sender);
    address implAddressV2 = Upgrades.getImplementationAddress(address(proxy));
    
    assertEq(Upgrades.getAdminAddress(address(proxy)), adminAddress);

    assertEq(instance.greeting(), "resetted");
    assertFalse(implAddressV2 == implAddressV1);
  }

  function testBeacon() public {
    IBeacon beacon = Upgrades.deployBeacon("MyToken.sol", msg.sender);
    address implAddressV1 = beacon.implementation();

    Proxy proxy = Upgrades.deployBeaconProxy(address(beacon), abi.encodeCall(MyToken.initialize, ("hello", msg.sender)));
    MyToken instance = MyToken(address(proxy));

    assertEq(instance.name(), "MyToken");
    assertEq(instance.greeting(), "hello");
    assertEq(instance.owner(), msg.sender);

    Upgrades.upgradeBeacon(address(beacon), "MyTokenV2.sol", msg.sender);
    address implAddressV2 = beacon.implementation();

    MyTokenV2(address(instance)).resetGreeting();

    assertEq(instance.greeting(), "resetted");
    assertFalse(implAddressV2 == implAddressV1);
  }
}
