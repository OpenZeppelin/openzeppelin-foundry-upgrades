
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {Vm} from "forge-std/Vm.sol";
import {Utils} from "./internal/Utils.sol";
import {Core} from "./internal/Core.sol";

/**
 * @dev Library for managing upgradeable contracts from Forge tests, without validations.
 *
 * Can be used with `forge coverage`. Requires implementation contracts to be instantiated first.
 * Does not require `--ffi` and does not require a clean compilation before each run.
 *
 * Not supported for OpenZeppelin Defender deployments.
 *
 * WARNING: Not recommended for use in Forge scripts.
 * UnsafeLegacyUpgrades.sol does not validate whether your contracts are upgrade safe or whether new implementations are compatible with previous ones.
 * Use LegacyUpgrades.sol if you want validations to be run.
 * 
 * @notice Compatible with existing deployments that use OpenZeppelin Contracts v4.
 */
library UnsafeLegacyUpgrades {
    /**
     * @dev Upgrades a proxy to a new implementation contract address. Only supported for UUPS or transparent proxies.
     *
     * @param proxy Address of the proxy to upgrade
     * @param newImpl Address of the new implementation contract to upgrade to
     * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no function needs to be called during the upgrade
     */
    function upgradeProxy(address proxy, address newImpl, bytes memory data) internal {
        Core.upgradeProxyTo(proxy, newImpl, data);
    }

    /**
     * @notice For tests only. If broadcasting in scripts, use the `--sender <ADDRESS>` option with `forge script` instead.
     *
     * @dev Upgrades a proxy to a new implementation contract address. Only supported for UUPS or transparent proxies.
     *
     * This function provides an additional `tryCaller` parameter to test an upgrade using a specific caller address.
     * Use this if you encounter `OwnableUnauthorizedAccount` errors in your tests.
     *
     * @param proxy Address of the proxy to upgrade
     * @param newImpl Address of the new implementation contract to upgrade to
     * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no function needs to be called during the upgrade
     * @param tryCaller Address to use as the caller of the upgrade function. This should be the address that owns the proxy or its ProxyAdmin.
     */
    function upgradeProxy(address proxy, address newImpl, bytes memory data, address tryCaller) internal {
        Core.upgradeProxyTo(proxy, newImpl, data, tryCaller);
    }

    /**
     * @dev Upgrades a beacon to a new implementation contract address.
     *
     * @param beacon Address of the beacon to upgrade
     * @param newImpl Address of the new implementation contract to upgrade to
     */
    function upgradeBeacon(address beacon, address newImpl) internal {
        Core.upgradeBeaconTo(beacon, newImpl);
    }

    /**
     * @notice For tests only. If broadcasting in scripts, use the `--sender <ADDRESS>` option with `forge script` instead.
     *
     * @dev Upgrades a beacon to a new implementation contract address.
     *
     * This function provides an additional `tryCaller` parameter to test an upgrade using a specific caller address.
     * Use this if you encounter `OwnableUnauthorizedAccount` errors in your tests.
     *
     * @param beacon Address of the beacon to upgrade
     * @param newImpl Address of the new implementation contract to upgrade to
     * @param tryCaller Address to use as the caller of the upgrade function. This should be the address that owns the beacon.
     */
    function upgradeBeacon(address beacon, address newImpl, address tryCaller) internal {
        Core.upgradeBeaconTo(beacon, newImpl, tryCaller);
     }
}