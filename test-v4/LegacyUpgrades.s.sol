// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {Greeter} from "./contracts/Greeter.sol";
import {GreeterProxiable} from "./contracts/GreeterProxiable.sol";
import {GreeterV2} from "./contracts/GreeterV2.sol";
import {GreeterV2Proxiable} from "./contracts/GreeterV2Proxiable.sol";

import {LegacyUpgrades, Options} from "openzeppelin-foundry-upgrades/LegacyUpgrades.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

/**
 * @dev Sample script to upgrade OpenZeppelin Contracts v4 deployments using transparent, UUPS, and beacon proxies.
 */
contract LegacyUpgradesScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        Options memory opts;

        // validate and deploy implementations to be used in proxies
        address greeter = LegacyUpgrades.deployImplementation("Greeter.sol", opts);
        address greeterProxiable = LegacyUpgrades.deployImplementation("GreeterProxiable.sol", opts);

        // deploy each type of proxy for testing
        address proxyAdmin = address(new ProxyAdmin());
        address transparentProxy = address(new TransparentUpgradeableProxy(greeter, proxyAdmin, abi.encodeCall(Greeter.initialize, ("hello"))));

        address uupsProxy = address(new ERC1967Proxy(
            greeterProxiable,
            abi.encodeCall(GreeterProxiable.initialize, ("hello"))
        ));

        address beacon = address(new UpgradeableBeacon(greeter));
        new BeaconProxy(beacon, abi.encodeCall(Greeter.initialize, ("hello")));

        // example upgrade of an existing transparent proxy
        LegacyUpgrades.upgradeProxy(transparentProxy, "GreeterV2.sol", abi.encodeCall(GreeterV2.resetGreeting, ()));

        // example upgrade of an existing UUPS proxy
        LegacyUpgrades.upgradeProxy(
            uupsProxy,
            "GreeterV2Proxiable.sol",
            abi.encodeCall(GreeterV2Proxiable.resetGreeting, ())
        );

        // example upgrade of an existing beacon
        LegacyUpgrades.upgradeBeacon(beacon, "GreeterV2.sol");

        vm.stopBroadcast();
    }
}
