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
import {strings} from "solidity-stringutils/src/strings.sol";

import {Versions} from "./internal/Versions.sol";
import {Utils} from "./internal/Utils.sol";

struct Options {
    /**
     * The reference contract to use for storage layout comparisons, e.g. "ContractV1.sol" or "ContractV1.sol:ContractV1".
     * If not set, attempts to use the `@custom:oz-upgrades-from <reference>` annotation from the contract.
     */
    string referenceContract;
    /**
     * Encoded constructor arguments for the implementation contract.
     * Note that these are different from initializer arguments, and will be used in the deployment of the implementation contract itself.
     * Can be used to initialize immutable variables.
     */
    bytes constructorData;
    /**
     * Selectively disable one or more validation errors. Comma-separated list that must be compatible with the
     * --unsafeAllow option described in https://docs.openzeppelin.com/upgrades-plugins/1.x/api-core#usage
     */
    string unsafeAllow;
    /**
     * Configure storage layout check to allow variable renaming
     */
    bool unsafeAllowRenames;
    /**
     * Skips checking for storage layout compatibility errors. This is a dangerous option meant to be used as a last resort.
     */
    bool unsafeSkipStorageCheck;
    /**
     * Skips all upgrade safety checks. This is a dangerous option meant to be used as a last resort.
     */
    bool unsafeSkipAllChecks;
}

/**
 * @dev Library for deploying and managing upgradeable contracts from Forge scripts or tests.
 */
library Upgrades {
    /**
     * @dev Deploys a UUPS proxy using the given contract as the implementation.
     *
     * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param initializerData Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
     * @param opts Common options
     * @return Proxy address
     */
    function deployUUPSProxy(
        string memory contractName,
        bytes memory initializerData,
        Options memory opts
    ) internal returns (address) {
        address impl = deployImplementation(contractName, opts);
        return address(new ERC1967Proxy(impl, initializerData));
    }

    /**
     * @dev Deploys a UUPS proxy using the given contract as the implementation.
     *
     * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param initializerData Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
     * @return Proxy address
     */
    function deployUUPSProxy(string memory contractName, bytes memory initializerData) internal returns (address) {
        Options memory opts;
        return deployUUPSProxy(contractName, initializerData, opts);
    }

    /**
     * @dev Deploys a transparent proxy using the given contract as the implementation.
     *
     * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param initialOwner Address to set as the owner of the ProxyAdmin contract which gets deployed by the proxy
     * @param initializerData Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
     * @param opts Common options
     * @return Proxy address
     */
    function deployTransparentProxy(
        string memory contractName,
        address initialOwner,
        bytes memory initializerData,
        Options memory opts
    ) internal returns (address) {
        address impl = deployImplementation(contractName, opts);
        return address(new TransparentUpgradeableProxy(impl, initialOwner, initializerData));
    }

    /**
     * @dev Deploys a transparent proxy using the given contract as the implementation.
     *
     * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param initialOwner Address to set as the owner of the ProxyAdmin contract which gets deployed by the proxy
     * @param initializerData Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
     * @return Proxy address
     */
    function deployTransparentProxy(
        string memory contractName,
        address initialOwner,
        bytes memory initializerData
    ) internal returns (address) {
        Options memory opts;
        return deployTransparentProxy(contractName, initialOwner, initializerData, opts);
    }

    /**
     * @dev Upgrades a proxy to a new implementation contract. Only supported for UUPS or transparent proxies.
     *
     * Requires that either the `referenceContract` option is set, or the new implementation contract has a `@custom:oz-upgrades-from <reference>` annotation.
     *
     * @param proxy Address of the proxy to upgrade
     * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no function needs to be called during the upgrade
     * @param opts Common options
     */
    function upgradeProxy(address proxy, string memory contractName, bytes memory data, Options memory opts) internal {
        address newImpl = prepareUpgrade(contractName, opts);

        Vm vm = Vm(CHEATCODE_ADDRESS);

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
     * @dev Upgrades a proxy to a new implementation contract. Only supported for UUPS or transparent proxies.
     *
     * Requires that either the `referenceContract` option is set, or the new implementation contract has a `@custom:oz-upgrades-from <reference>` annotation.
     *
     * @param proxy Address of the proxy to upgrade
     * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no function needs to be called during the upgrade
     */
    function upgradeProxy(address proxy, string memory contractName, bytes memory data) internal {
        Options memory opts;
        upgradeProxy(proxy, contractName, data, opts);
    }

    /**
     * @notice For tests only. If broadcasting in scripts, use the `--sender <ADDRESS>` option with `forge script` instead.
     *
     * @dev Upgrades a proxy to a new implementation contract. Only supported for UUPS or transparent proxies.
     *
     * Requires that either the `referenceContract` option is set, or the new implementation contract has a `@custom:oz-upgrades-from <reference>` annotation.
     *
     * This function provides an additional `tryCaller` parameter to test an upgrade using a specific caller address.
     * Use this if you encounter `OwnableUnauthorizedAccount` errors in your tests.
     *
     * @param proxy Address of the proxy to upgrade
     * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no function needs to be called during the upgrade
     * @param opts Common options
     * @param tryCaller Address to use as the caller of the upgrade function. This should be the address that owns the proxy or its ProxyAdmin.
     */
    function upgradeProxy(
        address proxy,
        string memory contractName,
        bytes memory data,
        Options memory opts,
        address tryCaller
    ) internal tryPrank(tryCaller) {
        upgradeProxy(proxy, contractName, data, opts);
    }

    /**
     * @notice For tests only. If broadcasting in scripts, use the `--sender <ADDRESS>` option with `forge script` instead.
     *
     * @dev Upgrades a proxy to a new implementation contract. Only supported for UUPS or transparent proxies.
     *
     * Requires that either the `referenceContract` option is set, or the new implementation contract has a `@custom:oz-upgrades-from <reference>` annotation.
     *
     * This function provides an additional `tryCaller` parameter to test an upgrade using a specific caller address.
     * Use this if you encounter `OwnableUnauthorizedAccount` errors in your tests.
     *
     * @param proxy Address of the proxy to upgrade
     * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no function needs to be called during the upgrade
     * @param tryCaller Address to use as the caller of the upgrade function. This should be the address that owns the proxy or its ProxyAdmin.
     */
    function upgradeProxy(
        address proxy,
        string memory contractName,
        bytes memory data,
        address tryCaller
    ) internal tryPrank(tryCaller) {
        Options memory opts;
        upgradeProxy(proxy, contractName, data, opts, tryCaller);
    }

    /**
     * @dev Deploys an upgradeable beacon using the given contract as the implementation.
     *
     * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param initialOwner Address to set as the owner of the UpgradeableBeacon contract which gets deployed
     * @param opts Common options
     * @return Beacon address
     */
    function deployBeacon(
        string memory contractName,
        address initialOwner,
        Options memory opts
    ) internal returns (address) {
        address impl = deployImplementation(contractName, opts);
        return address(new UpgradeableBeacon(impl, initialOwner));
    }

    /**
     * @dev Deploys an upgradeable beacon using the given contract as the implementation.
     *
     * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param initialOwner Address to set as the owner of the UpgradeableBeacon contract which gets deployed
     * @return Beacon address
     */
    function deployBeacon(string memory contractName, address initialOwner) internal returns (address) {
        Options memory opts;
        return deployBeacon(contractName, initialOwner, opts);
    }

    /**
     * @dev Upgrades a beacon to a new implementation contract.
     *
     * Requires that either the `referenceContract` option is set, or the new implementation contract has a `@custom:oz-upgrades-from <reference>` annotation.
     *
     * @param beacon Address of the beacon to upgrade
     * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param opts Common options
     */
    function upgradeBeacon(address beacon, string memory contractName, Options memory opts) internal {
        address newImpl = prepareUpgrade(contractName, opts);
        UpgradeableBeacon(beacon).upgradeTo(newImpl);
    }

    /**
     * @dev Upgrades a beacon to a new implementation contract.
     *
     * Requires that either the `referenceContract` option is set, or the new implementation contract has a `@custom:oz-upgrades-from <reference>` annotation.
     *
     * @param beacon Address of the beacon to upgrade
     * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     */
    function upgradeBeacon(address beacon, string memory contractName) internal {
        Options memory opts;
        upgradeBeacon(beacon, contractName, opts);
    }

    /**
     * @notice For tests only. If broadcasting in scripts, use the `--sender <ADDRESS>` option with `forge script` instead.
     *
     * @dev Upgrades a beacon to a new implementation contract.
     *
     * Requires that either the `referenceContract` option is set, or the new implementation contract has a `@custom:oz-upgrades-from <reference>` annotation.
     *
     * This function provides an additional `tryCaller` parameter to test an upgrade using a specific caller address.
     * Use this if you encounter `OwnableUnauthorizedAccount` errors in your tests.
     *
     * @param beacon Address of the beacon to upgrade
     * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param opts Common options
     * @param tryCaller Address to use as the caller of the upgrade function. This should be the address that owns the beacon.
     */
    function upgradeBeacon(
        address beacon,
        string memory contractName,
        Options memory opts,
        address tryCaller
    ) internal tryPrank(tryCaller) {
        upgradeBeacon(beacon, contractName, opts);
    }

    /**
     * @notice For tests only. If broadcasting in scripts, use the `--sender <ADDRESS>` option with `forge script` instead.
     *
     * @dev Upgrades a beacon to a new implementation contract.
     *
     * Requires that either the `referenceContract` option is set, or the new implementation contract has a `@custom:oz-upgrades-from <reference>` annotation.
     *
     * This function provides an additional `tryCaller` parameter to test an upgrade using a specific caller address.
     * Use this if you encounter `OwnableUnauthorizedAccount` errors in your tests.
     *
     * @param beacon Address of the beacon to upgrade
     * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param tryCaller Address to use as the caller of the upgrade function. This should be the address that owns the beacon.
     */
    function upgradeBeacon(address beacon, string memory contractName, address tryCaller) internal tryPrank(tryCaller) {
        Options memory opts;
        upgradeBeacon(beacon, contractName, opts, tryCaller);
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
     * @dev Validates an implementation contract, but does not deploy it.
     *
     * @param contractName Name of the contract to validate, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param opts Common options
     */
    function validateImplementation(string memory contractName, Options memory opts) internal {
        _validate(contractName, opts, false);
    }

    /**
     * @dev Validates and deploys an implementation contract, and returns its address.
     *
     * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param opts Common options
     * @return Address of the implementation contract
     */
    function deployImplementation(string memory contractName, Options memory opts) internal returns (address) {
        validateImplementation(contractName, opts);
        return _deploy(contractName, opts.constructorData);
    }

    /**
     * @dev Validates a new implementation contract in comparison with a reference contract, but does not deploy it.
     *
     * Requires that either the `referenceContract` option is set, or the contract has a `@custom:oz-upgrades-from <reference>` annotation.
     *
     * @param contractName Name of the contract to validate, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param opts Common options
     */
    function validateUpgrade(string memory contractName, Options memory opts) internal {
        _validate(contractName, opts, true);
    }

    /**
     * @dev Validates a new implementation contract in comparison with a reference contract, deploys the new implementation contract,
     * and returns its address.
     *
     * Requires that either the `referenceContract` option is set, or the contract has a `@custom:oz-upgrades-from <reference>` annotation.
     *
     * Use this method to prepare an upgrade to be run from an admin address you do not control directly or cannot use from your deployment environment.
     *
     * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param opts Common options
     * @return Address of the new implementation contract
     */
    function prepareUpgrade(string memory contractName, Options memory opts) internal returns (address) {
        validateUpgrade(contractName, opts);
        return _deploy(contractName, opts.constructorData);
    }

    /**
     * @dev Gets the admin address of a transparent proxy from its ERC1967 admin storage slot.
     *
     * @param proxy Address of a transparent proxy
     * @return Admin address
     */
    function getAdminAddress(address proxy) internal view returns (address) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        bytes32 adminSlot = vm.load(proxy, ERC1967Utils.ADMIN_SLOT);
        return address(uint160(uint256(adminSlot)));
    }

    /**
     * @dev Gets the implementation address of a transparent or UUPS proxy from its ERC1967 implementation storage slot.
     *
     * @param proxy Address of a transparent or UUPS proxy
     * @return Implementation address
     */
    function getImplementationAddress(address proxy) internal view returns (address) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        bytes32 implSlot = vm.load(proxy, ERC1967Utils.IMPLEMENTATION_SLOT);
        return address(uint160(uint256(implSlot)));
    }

    /**
     * @dev Gets the beacon address of a beacon proxy from its ERC1967 beacon storage slot.
     *
     * @param proxy Address of a beacon proxy
     * @return Beacon address
     */
    function getBeaconAddress(address proxy) internal view returns (address) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        bytes32 beaconSlot = vm.load(proxy, ERC1967Utils.BEACON_SLOT);
        return address(uint160(uint256(beaconSlot)));
    }

    /**
     * @notice For tests only. If broadcasting in scripts, use the `--sender <ADDRESS>` option with `forge script` instead.
     *
     * @dev Runs a function as a prank, or just runs the function normally if the prank could not be started.
     */
    modifier tryPrank(address deployer) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        try vm.startPrank(deployer) {
            _;
            vm.stopPrank();
        } catch {
            _;
        }
    }

    using strings for *;
    address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function _validate(string memory contractName, Options memory opts, bool requireReference) private {
        if (opts.unsafeSkipAllChecks) {
            return;
        }

        string[] memory inputs = _buildValidateCommand(contractName, opts, requireReference);
        Vm.FfiResult memory result = Utils.runAsBashCommand(inputs);
        string memory stdout = string(result.stdout);

        // CLI validate command uses exit code to indicate if the validation passed or failed.
        // As an extra precaution, we also check stdout for "SUCCESS" to ensure it actually ran.
        if (result.exitCode == 0 && stdout.toSlice().contains("SUCCESS".toSlice())) {
            return;
        } else if (result.stderr.length > 0) {
            // Validations failed to run
            revert(string.concat("Failed to run upgrade safety validation: ", string(result.stderr)));
        } else {
            // Validations ran but some contracts were not upgrade safe
            revert(string.concat("Upgrade safety validation failed:\n", stdout));
        }
    }

    function _buildValidateCommand(
        string memory contractName,
        Options memory opts,
        bool requireReference
    ) private returns (string[] memory) {
        string memory outDir = Utils.getOutDir();

        string[] memory inputBuilder = new string[](255);

        uint8 i = 0;

        inputBuilder[i++] = "npx";
        inputBuilder[i++] = string.concat("@openzeppelin/upgrades-core@", Versions.UPGRADES_CORE);
        inputBuilder[i++] = "validate";
        inputBuilder[i++] = string.concat(outDir, "/build-info");
        inputBuilder[i++] = "--contract";
        inputBuilder[i++] = Utils.getFullyQualifiedName(contractName, outDir);

        if (bytes(opts.referenceContract).length != 0) {
            inputBuilder[i++] = "--reference";
            inputBuilder[i++] = Utils.getFullyQualifiedName(opts.referenceContract, outDir);
        }

        if (opts.unsafeSkipStorageCheck) {
            inputBuilder[i++] = "--unsafeSkipStorageCheck";
        } else if (requireReference) {
            inputBuilder[i++] = "--requireReference";
        }

        if (bytes(opts.unsafeAllow).length != 0) {
            inputBuilder[i++] = "--unsafeAllow";
            inputBuilder[i++] = opts.unsafeAllow;
        }

        if (opts.unsafeAllowRenames) {
            inputBuilder[i++] = "--unsafeAllowRenames";
        }

        // Create a copy of inputs but with the correct length
        string[] memory inputs = new string[](i);
        for (uint8 j = 0; j < i; j++) {
            inputs[j] = inputBuilder[j];
        }

        return inputs;
    }

    function _deploy(string memory contractName, bytes memory constructorData) private returns (address) {
        bytes memory creationCode = Vm(CHEATCODE_ADDRESS).getCode(contractName);
        address deployedAddress = _deployFromBytecode(abi.encodePacked(creationCode, constructorData));
        if (deployedAddress == address(0)) {
            revert(
                string.concat(
                    "Failed to deploy contract ",
                    contractName,
                    ' using constructor data "',
                    string(constructorData),
                    '"'
                )
            );
        }
        return deployedAddress;
    }

    function _deployFromBytecode(bytes memory bytecode) private returns (address) {
        address addr;
        assembly {
            addr := create(0, add(bytecode, 32), mload(bytecode))
        }
        return addr;
    }
}
