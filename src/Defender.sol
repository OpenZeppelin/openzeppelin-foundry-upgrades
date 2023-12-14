// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ITransparentUpgradeableProxy, TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {strings} from "solidity-stringutils/strings.sol";

import {Versions} from "./internal/Versions.sol";

/**
 * @dev Library for deploying and managing upgradeable contracts from Forge scripts or tests.
 */
library Defender {
    address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function deployContract(string memory contractName) internal {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        console.log("Deploying ", contractName);
    }

    using strings for *;

    function _getOutDir() private returns (string memory) {
        Vm vm = Vm(CHEATCODE_ADDRESS);
        string memory foundryTomlPath = string.concat(vm.projectRoot(), "/foundry.toml");
        string memory foundryToml = vm.readFile(foundryTomlPath);
        console.log("foundry.toml ", foundryToml);

        return "out";
    }
}
