// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {LegacyUpgrades, Options} from "openzeppelin-foundry-upgrades/LegacyUpgrades.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

import {Greeter} from "./contracts/Greeter.sol";
import {GreeterProxiable} from "./contracts/GreeterProxiable.sol";
import {GreeterV2} from "./contracts/GreeterV2.sol";
import {GreeterV2Proxiable} from "./contracts/GreeterV2Proxiable.sol";

/**
 * @dev Tests for the LegacyUpgrades library.
 */
contract LegacyUpgradesTest is Test {
    address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function testUUPS() public {
        Options memory opts;
        address impl = LegacyUpgrades.deployImplementation("GreeterProxiable.sol", opts);

        Vm(CHEATCODE_ADDRESS).startPrank(msg.sender);
        address proxy = address(new ERC1967Proxy(
            impl,
            abi.encodeCall(Greeter.initialize, ("hello"))
        ));
        Vm(CHEATCODE_ADDRESS).stopPrank();

        Greeter instance = Greeter(proxy);
        address implAddressV1 = LegacyUpgrades.getImplementationAddress(proxy);

        assertEq(instance.greeting(), "hello");

        LegacyUpgrades.upgradeProxy(
            proxy,
            "GreeterV2Proxiable.sol",
            abi.encodeCall(GreeterV2Proxiable.resetGreeting, ()),
            msg.sender
        );
        address implAddressV2 = LegacyUpgrades.getImplementationAddress(proxy);

        assertEq(instance.greeting(), "resetted");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testTransparent() public {
        Options memory opts;
        address impl = LegacyUpgrades.deployImplementation("Greeter.sol", opts);

        Vm(CHEATCODE_ADDRESS).startPrank(msg.sender);
        address proxyAdmin = address(new ProxyAdmin());
        address proxy = address(new TransparentUpgradeableProxy(
            impl,
            proxyAdmin,
            abi.encodeCall(Greeter.initialize, ("hello"))
        ));
        Vm(CHEATCODE_ADDRESS).stopPrank();

        Greeter instance = Greeter(proxy);
        address implAddressV1 = LegacyUpgrades.getImplementationAddress(proxy);
        address adminAddress = LegacyUpgrades.getAdminAddress(proxy);

        assertFalse(adminAddress == address(0));

        assertEq(instance.greeting(), "hello");

        LegacyUpgrades.upgradeProxy(proxy, "GreeterV2.sol", abi.encodeCall(GreeterV2.resetGreeting, ()), msg.sender);
        address implAddressV2 = LegacyUpgrades.getImplementationAddress(proxy);

        assertEq(LegacyUpgrades.getAdminAddress(proxy), adminAddress);

        assertEq(instance.greeting(), "resetted");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testBeacon() public {
        Options memory opts;
        address implAddressV1 = LegacyUpgrades.deployImplementation("Greeter.sol", opts);

        Vm(CHEATCODE_ADDRESS).startPrank(msg.sender);
        address beacon = address(new UpgradeableBeacon(implAddressV1));
        address proxy = address(new BeaconProxy(beacon, abi.encodeCall(Greeter.initialize, ("hello"))));
        Vm(CHEATCODE_ADDRESS).stopPrank();

        Greeter instance = Greeter(proxy);

        assertEq(LegacyUpgrades.getBeaconAddress(proxy), beacon);

        assertEq(instance.greeting(), "hello");

        LegacyUpgrades.upgradeBeacon(beacon, "GreeterV2.sol", msg.sender);
        address implAddressV2 = IBeacon(beacon).implementation();

        Vm(CHEATCODE_ADDRESS).prank(msg.sender);
        GreeterV2(address(instance)).setGreeting("modified");

        assertEq(instance.greeting(), "modified");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testUpgradeProxyWithoutCaller() public {
        Options memory opts;
        address impl = LegacyUpgrades.deployImplementation("GreeterProxiable.sol", opts);

        Vm(CHEATCODE_ADDRESS).startPrank(msg.sender);
        address proxy = address(new ERC1967Proxy(
            impl,
            abi.encodeCall(Greeter.initialize, ("hello"))
        ));
        LegacyUpgrades.upgradeProxy(proxy, "GreeterV2Proxiable.sol", abi.encodeCall(GreeterV2Proxiable.resetGreeting, ()));
        Vm(CHEATCODE_ADDRESS).stopPrank();
    }

    function testUpgradeBeaconWithoutCaller() public {
        Options memory opts;
        address impl = LegacyUpgrades.deployImplementation("Greeter.sol", opts);

        Vm(CHEATCODE_ADDRESS).startPrank(msg.sender);
        address beacon = address(new UpgradeableBeacon(impl));
        LegacyUpgrades.upgradeBeacon(beacon, "GreeterV2.sol");
        Vm(CHEATCODE_ADDRESS).stopPrank();
    }
}
