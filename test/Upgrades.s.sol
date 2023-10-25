// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {MyToken} from "./contracts/MyToken.sol";
import {MyTokenV2} from "./contracts/MyTokenV2.sol";
import {MyTokenProxiable} from "./contracts/MyTokenProxiable.sol";
import {MyTokenProxiableV2} from "./contracts/MyTokenProxiableV2.sol";

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";

contract UpgradesScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // example deployment and upgrade of a transparent proxy
        address transparentProxy = address(
            Upgrades.deployTransparentProxy(
                "MyToken.sol",
                msg.sender,
                abi.encodeCall(MyToken.initialize, ("hello", msg.sender))
            )
        );
        Upgrades.upgradeProxy(transparentProxy, "MyTokenV2.sol", abi.encodeCall(MyTokenV2.resetGreeting, ()));

        // example deployment and upgrade of a UUPS proxy
        address uupsProxy = address(
            Upgrades.deployUUPSProxy(
                "MyTokenProxiable.sol",
                abi.encodeCall(MyTokenProxiable.initialize, ("hello", msg.sender))
            )
        );
        Upgrades.upgradeProxy(
            uupsProxy,
            "MyTokenProxiableV2.sol",
            abi.encodeCall(MyTokenProxiableV2.resetGreeting, ())
        );

        // example deployment of a beacon proxy and upgrade of the beacon
        address beacon = address(Upgrades.deployBeacon("MyToken.sol", msg.sender));
        Upgrades.deployBeaconProxy(beacon, abi.encodeCall(MyToken.initialize, ("hello", msg.sender)));
        Upgrades.upgradeBeacon(beacon, "MyTokenV2.sol");

        vm.stopBroadcast();
    }
}
