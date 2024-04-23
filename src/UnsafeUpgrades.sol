// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ITransparentUpgradeableProxy, TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {Vm} from "forge-std/Vm.sol";
import {Utils} from "./internal/Utils.sol";
import {Upgrades} from "./Upgrades.sol";

/**
 * @dev Library for deploying and managing upgradeable contracts from Forge tests, without validations.
 *
 * Requires implementation contracts to be instantiated first. Can be used with `forge coverage`.
 * Does not require `--ffi` and does not require a clean compilation before each run.
 * Not supported for OpenZeppelin Defender deployments.
 *
 * WARNING: Not recommended for use in Forge scripts.
 * UnsafeUpgrades.sol does not validate whether your contracts are upgrade safe or whether new implementations are compatible with previous ones.
 * Use Upgrades.sol if you want validations to be run.
 */
library UnsafeUpgrades {
    /**
     * @dev Deploys a UUPS proxy using the given contract as the implementation.
     *
     * @param impl Address of the contract to use as the implementation
     * @param initializerData Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
     * @return Proxy address
     */
    function deployUUPSProxy(address impl, bytes memory initializerData) internal returns (address) {
        return address(new ERC1967Proxy(impl, initializerData));
    }

    /**
     * @dev Deploys a transparent proxy using the given contract as the implementation.
     *
     * @param impl Address of the contract to use as the implementation
     * @param initialOwner Address to set as the owner of the ProxyAdmin contract which gets deployed by the proxy
     * @param initializerData Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
     * @return Proxy address
     */
    function deployTransparentProxy(
        address impl,
        address initialOwner,
        bytes memory initializerData
    ) internal returns (address) {
        return address(new TransparentUpgradeableProxy(impl, initialOwner, initializerData));
    }

    /**
     * @dev Upgrades a proxy to a new implementation contract. Only supported for UUPS or transparent proxies.
     *
     * @param proxy Address of the proxy to upgrade
     * @param newImpl Address of the new implementation contract to upgrade to
     * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no function needs to be called during the upgrade
     */
    function upgradeProxy(address proxy, address newImpl, bytes memory data) internal {
        Vm vm = Vm(Utils.CHEATCODE_ADDRESS);

        bytes32 adminSlot = vm.load(proxy, ERC1967Utils.ADMIN_SLOT);
        if (adminSlot == bytes32(0)) {
            // No admin contract: upgrade directly using interface
            ITransparentUpgradeableProxy(proxy).upgradeToAndCall(newImpl, data);
        } else {
            ProxyAdmin admin = ProxyAdmin(address(uint160(uint256(adminSlot))));
            admin.upgradeAndCall(ITransparentUpgradeableProxy(proxy), newImpl, data);
        }
    }

    /**
     * @notice For tests only. If broadcasting in scripts, use the `--sender <ADDRESS>` option with `forge script` instead.
     *
     * @dev Upgrades a proxy to a new implementation contract. Only supported for UUPS or transparent proxies.
     *
     * This function provides an additional `tryCaller` parameter to test an upgrade using a specific caller address.
     * Use this if you encounter `OwnableUnauthorizedAccount` errors in your tests.
     *
     * @param proxy Address of the proxy to upgrade
     * @param newImpl Address of the new implementation contract to upgrade to
     * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no function needs to be called during the upgrade
     * @param tryCaller Address to use as the caller of the upgrade function. This should be the address that owns the proxy or its ProxyAdmin.
     */
    function upgradeProxy(
        address proxy,
        address newImpl,
        bytes memory data,
        address tryCaller
    ) internal tryPrank(tryCaller) {
        upgradeProxy(proxy, newImpl, data);
    }

    /**
     * @dev Deploys an upgradeable beacon using the given contract as the implementation.
     *
     * @param impl Address of the contract to use as the implementation
     * @param initialOwner Address to set as the owner of the UpgradeableBeacon contract which gets deployed
     * @return Beacon address
     */
    function deployBeacon(address impl, address initialOwner) internal returns (address) {
        return address(new UpgradeableBeacon(impl, initialOwner));
    }

    /**
     * @dev Upgrades a beacon to a new implementation contract.
     *
     * @param beacon Address of the beacon to upgrade
     * @param newImpl Address of the new implementation contract to upgrade to
     */
    function upgradeBeacon(address beacon, address newImpl) internal {
        UpgradeableBeacon(beacon).upgradeTo(newImpl);
    }

    /**
     * @notice For tests only. If broadcasting in scripts, use the `--sender <ADDRESS>` option with `forge script` instead.
     *
     * @dev Upgrades a beacon to a new implementation contract.
     *
     * This function provides an additional `tryCaller` parameter to test an upgrade using a specific caller address.
     * Use this if you encounter `OwnableUnauthorizedAccount` errors in your tests.
     *
     * @param beacon Address of the beacon to upgrade
     * @param newImpl Address of the new implementation contract to upgrade to
     * @param tryCaller Address to use as the caller of the upgrade function. This should be the address that owns the beacon.
     */
    function upgradeBeacon(address beacon, address newImpl, address tryCaller) internal tryPrank(tryCaller) {
        upgradeBeacon(beacon, newImpl);
    }

    /**
     * @dev Deploys a beacon proxy using the given beacon and call data.
     *
     * @param beacon Address of the beacon to use
     * @param data Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
     * @return Proxy address
     */
    function deployBeaconProxy(address beacon, bytes memory data) internal returns (address) {
        return address(new BeaconProxy(beacon, data));
    }

    /**
     * @notice For tests only. If broadcasting in scripts, use the `--sender <ADDRESS>` option with `forge script` instead.
     *
     * @dev Runs a function as a prank, or just runs the function normally if the prank could not be started.
     */
    modifier tryPrank(address deployer) {
        Vm vm = Vm(Utils.CHEATCODE_ADDRESS);

        try vm.startPrank(deployer) {
            _;
            vm.stopPrank();
        } catch {
            _;
        }
    }
}
