// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/MyTokenV2.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract MyTokenTest is Test {

  function testUUPS() public {
    Proxy proxy = Upgrades.deployUUPSProxy(type(MyToken).creationCode, abi.encodeCall(MyToken.initialize, ("hello", msg.sender)));
    MyToken instance = MyToken(address(proxy));
    address implAddressV1 = Upgrades.getImplementationAddress(address(proxy));

    assertEq(instance.name(), "MyToken");
    assertEq(instance.greeting(), "hello");
    assertEq(instance.owner(), msg.sender);

    Upgrades.upgradeProxy(address(proxy), type(MyTokenV2).creationCode, msg.sender, abi.encodeCall(MyTokenV2.resetGreeting, ()));
    address implAddressV2 = Upgrades.getImplementationAddress(address(proxy));

    assertEq(instance.greeting(), "resetted");
    assertFalse(implAddressV2 == implAddressV1);

  }

  function testTransparent() public {
    Proxy proxy = Upgrades.deployTransparentProxy(type(MyToken).creationCode, msg.sender, abi.encodeCall(MyToken.initialize, ("hello", msg.sender)));
    MyToken instance = MyToken(address(proxy));
    address implAddressV1 = Upgrades.getImplementationAddress(address(proxy));
    address adminAddress = Upgrades.getAdminAddress(address(proxy));

    assertFalse(adminAddress == address(0));

    assertEq(instance.name(), "MyToken");
    assertEq(instance.greeting(), "hello");
    assertEq(instance.owner(), msg.sender);

    Upgrades.upgradeProxy(address(proxy), type(MyTokenV2).creationCode, msg.sender, abi.encodeCall(MyTokenV2.resetGreeting, ()));
    address implAddressV2 = Upgrades.getImplementationAddress(address(proxy));
    
    assertEq(Upgrades.getAdminAddress(address(proxy)), adminAddress);

    assertEq(instance.greeting(), "resetted");
    assertFalse(implAddressV2 == implAddressV1);
  }

  function testBeacon() public {
    IBeacon beacon = Upgrades.deployBeacon(type(MyToken).creationCode, msg.sender);
    address implAddressV1 = beacon.implementation();

    Proxy proxy = Upgrades.deployBeaconProxy(address(beacon), abi.encodeCall(MyToken.initialize, ("hello", msg.sender)));
    MyToken instance = MyToken(address(proxy));

    assertEq(instance.name(), "MyToken");
    assertEq(instance.greeting(), "hello");
    assertEq(instance.owner(), msg.sender);

    Upgrades.upgradeBeacon(address(beacon), type(MyTokenV2).creationCode, msg.sender);
    address implAddressV2 = beacon.implementation();

    MyTokenV2(address(instance)).resetGreeting();

    assertEq(instance.greeting(), "resetted");
    assertFalse(implAddressV2 == implAddressV1);
  }
}
