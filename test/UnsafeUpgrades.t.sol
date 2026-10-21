// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

import {Greeter} from "./contracts/Greeter.sol";
import {GreeterProxiable} from "./contracts/GreeterProxiable.sol";
import {GreeterV2} from "./contracts/GreeterV2.sol";
import {GreeterV2Proxiable} from "./contracts/GreeterV2Proxiable.sol";
import {WithConstructor, NoInitializer} from "./contracts/WithConstructor.sol";

/**
 * @dev Tests for the UnsafeUpgrades library.
 */
contract UnsafeUpgradesTest is Test {
    function testUUPS() public {
        address proxy = UnsafeUpgrades.deployUUPSProxy(
            address(new GreeterProxiable()),
            abi.encodeCall(Greeter.initialize, (msg.sender, "hello"))
        );
        Greeter instance = Greeter(proxy);
        address implAddressV1 = UnsafeUpgrades.getImplementationAddress(proxy);

        assertEq(instance.greeting(), "hello");

        UnsafeUpgrades.upgradeProxy(
            proxy,
            address(new GreeterV2Proxiable()),
            abi.encodeCall(GreeterV2Proxiable.resetGreeting, ()),
            msg.sender
        );
        address implAddressV2 = UnsafeUpgrades.getImplementationAddress(proxy);

        assertEq(instance.greeting(), "resetted");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testUUPS_upgradeWithoutData() public {
        address proxy = UnsafeUpgrades.deployUUPSProxy(
            address(new GreeterProxiable()),
            abi.encodeCall(Greeter.initialize, (msg.sender, "hello"))
        );
        address implAddressV1 = UnsafeUpgrades.getImplementationAddress(proxy);

        UnsafeUpgrades.upgradeProxy(proxy, address(new GreeterV2Proxiable()), "", msg.sender);
        address implAddressV2 = UnsafeUpgrades.getImplementationAddress(proxy);

        assertFalse(implAddressV2 == implAddressV1);
    }

    function testTransparent() public {
        address proxy = UnsafeUpgrades.deployTransparentProxy(
            address(new Greeter()),
            msg.sender,
            abi.encodeCall(Greeter.initialize, (msg.sender, "hello"))
        );
        Greeter instance = Greeter(proxy);
        address implAddressV1 = UnsafeUpgrades.getImplementationAddress(proxy);
        address adminAddress = UnsafeUpgrades.getAdminAddress(proxy);

        assertFalse(adminAddress == address(0));

        assertEq(instance.greeting(), "hello");

        UnsafeUpgrades.upgradeProxy(
            proxy,
            address(new GreeterV2()),
            abi.encodeCall(GreeterV2.resetGreeting, ()),
            msg.sender
        );
        address implAddressV2 = UnsafeUpgrades.getImplementationAddress(proxy);

        assertEq(UnsafeUpgrades.getAdminAddress(proxy), adminAddress);

        assertEq(instance.greeting(), "resetted");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testTransparent_upgradeWithoutData() public {
        address proxy = UnsafeUpgrades.deployTransparentProxy(
            address(new Greeter()),
            msg.sender,
            abi.encodeCall(Greeter.initialize, (msg.sender, "hello"))
        );
        address implAddressV1 = UnsafeUpgrades.getImplementationAddress(proxy);
        address adminAddress = UnsafeUpgrades.getAdminAddress(proxy);

        assertFalse(adminAddress == address(0));

        UnsafeUpgrades.upgradeProxy(proxy, address(new GreeterV2()), "", msg.sender);
        address implAddressV2 = UnsafeUpgrades.getImplementationAddress(proxy);

        assertEq(UnsafeUpgrades.getAdminAddress(proxy), adminAddress);

        assertFalse(implAddressV2 == implAddressV1);
    }

    function testBeacon() public {
        address beacon = UnsafeUpgrades.deployBeacon(address(new Greeter()), msg.sender);
        address implAddressV1 = IBeacon(beacon).implementation();

        address proxy = UnsafeUpgrades.deployBeaconProxy(
            beacon,
            abi.encodeCall(Greeter.initialize, (msg.sender, "hello"))
        );
        Greeter instance = Greeter(proxy);

        assertEq(UnsafeUpgrades.getBeaconAddress(proxy), beacon);

        assertEq(instance.greeting(), "hello");

        UnsafeUpgrades.upgradeBeacon(beacon, address(new GreeterV2()), msg.sender);
        address implAddressV2 = IBeacon(beacon).implementation();

        GreeterV2(address(instance)).resetGreeting();

        assertEq(instance.greeting(), "resetted");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testUpgradeProxyWithoutCaller() public {
        address proxy = UnsafeUpgrades.deployUUPSProxy(
            address(new GreeterProxiable()),
            abi.encodeCall(GreeterProxiable.initialize, (msg.sender, "hello"))
        );

        vm.startPrank(msg.sender);
        UnsafeUpgrades.upgradeProxy(
            proxy,
            address(new GreeterV2Proxiable()),
            abi.encodeCall(GreeterV2Proxiable.resetGreeting, ())
        );
        vm.stopPrank();
    }

    function testUpgradeBeaconWithoutCaller() public {
        address beacon = UnsafeUpgrades.deployBeacon(address(new Greeter()), msg.sender);

        vm.startPrank(msg.sender);
        UnsafeUpgrades.upgradeBeacon(beacon, address(new GreeterV2()));
        vm.stopPrank();
    }

    function testWithConstructor() public {
        address proxy = UnsafeUpgrades.deployTransparentProxy(
            address(new WithConstructor(123)),
            msg.sender,
            abi.encodeCall(WithConstructor.initialize, (456))
        );
        assertEq(WithConstructor(proxy).a(), 123);
        assertEq(WithConstructor(proxy).b(), 456);
    }

    // Implementation has no initializer
    function testNoInitializer() public {
        address impl = address(new NoInitializer(123));

        Invoker i = new Invoker();
        try i.deployTransparentProxy(impl, msg.sender, "") {
            fail();
        } catch (bytes memory reason) {
            assertEq(reason, abi.encodeWithSelector(ERC1967Proxy.ERC1967ProxyUninitialized.selector));
        }
    }

    function testDeployUUPSProxy_emptyInitializerData() public {
        address impl = address(new GreeterProxiable());

        Invoker i = new Invoker();
        try i.deployUUPSProxy(impl, "") {
            fail();
        } catch (bytes memory reason) {
            assertEq(reason, abi.encodeWithSelector(ERC1967Proxy.ERC1967ProxyUninitialized.selector));
        }
    }

    // Implementation has an initializer, but it is not called
    function testDeployTransparentProxy_emptyInitializerData() public {
        address impl = address(new Greeter());

        Invoker i = new Invoker();
        try i.deployTransparentProxy(impl, msg.sender, "") {
            fail();
        } catch (bytes memory reason) {
            assertEq(reason, abi.encodeWithSelector(ERC1967Proxy.ERC1967ProxyUninitialized.selector));
        }
    }
}

contract Invoker {
    function deployUUPSProxy(address impl, bytes memory data) public returns (address) {
        return UnsafeUpgrades.deployUUPSProxy(impl, data);
    }

    function deployTransparentProxy(address impl, address admin, bytes memory data) public returns (address) {
        return UnsafeUpgrades.deployTransparentProxy(impl, admin, data);
    }
}
