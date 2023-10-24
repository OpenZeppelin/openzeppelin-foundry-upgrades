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
import {console} from "forge-std/Console.sol";
import {strings} from "solidity-stringutils/strings.sol";

struct Options {
  // Foundry options
  string outDir;

  // Foundry Upgrades options
  bool unsafeSkipChecks;

  // @openzeppelin/upgrades-core CLI options
  string unsafeAllow;
  bool unsafeAllowRenames;
  bool unsafeSkipStorageCheck;
}

/**
 * @dev Library for deploying and managing upgradeable contracts from Forge scripts or tests.
 */
library Upgrades {
  using strings for *;

  address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

  function _validate(string memory contractName, string memory referenceContract, Options memory opts, bool requireReference) private {
    if (opts.unsafeSkipChecks) {
      return;
    }

    string[] memory inputs = _buildInputs(contractName, referenceContract, opts, requireReference);
    bytes memory result = Vm(CHEATCODE_ADDRESS).ffi(inputs);

    if (string(result).toSlice().endsWith("SUCCESS".toSlice())) {
      return;
    }
    revert(string.concat("Upgrade safety validation failed: ", string(result)));
  }

  function _buildInputs(string memory contractName, string memory referenceContract, Options memory opts, bool requireReference) private pure returns (string[] memory) {
    // TODO get defaults from foundry.toml
    string memory outDir = opts.outDir;
    if (bytes(outDir).length == 0) {
      outDir = "out";
    }

    string[] memory inputBuilder = new string[](255);

    uint8 i = 0;
    inputBuilder[i++] = "npx";
    inputBuilder[i++] = "@openzeppelin/upgrades-core";
    inputBuilder[i++] = "validate";
    inputBuilder[i++] = string.concat(outDir, "/build-info");
    inputBuilder[i++] = "--contract";
    inputBuilder[i++] = _toShortName(contractName);
    if (bytes(referenceContract).length != 0) {
      inputBuilder[i++] = "--reference";
      inputBuilder[i++] = _toShortName(referenceContract);
    }
    if (requireReference) {
      inputBuilder[i++] = "--requireReference";
    }
    if (bytes(opts.unsafeAllow).length != 0) {
      inputBuilder[i++] = "--unsafeAllow";
      inputBuilder[i++] = opts.unsafeAllow;
    }
    if (opts.unsafeAllowRenames) {
      inputBuilder[i++] = "--unsafeAllowRenames";
    }
    if (opts.unsafeSkipStorageCheck) {
      inputBuilder[i++] = "--unsafeSkipStorageCheck";
    }

    // Create a copy of inputs but with the correct length
    string[] memory inputs = new string[](i);
    for (uint8 j = 0; j < i; j++) {
      inputs[j] = inputBuilder[j];
    }

    return inputs;
  }

  function _toShortName(string memory contractName) private pure returns (string memory) {
    strings.slice memory name = contractName.toSlice();
    if (name.endsWith(".sol".toSlice())) {
      return name.until(".sol".toSlice()).toString();
    } else if (name.count(":".toSlice()) == 1) {
      // TODO lookup artifact file and return fully qualified name to support identical contract names in different files
      name.split(":".toSlice());
      return name.split(":".toSlice()).toString();
    } else {
      // TODO support artifact file name
      revert(string.concat("Contract name ", contractName, " must be in File.sol:Name or File.sol format"));
    }
  }

  /**
   * @dev Validates an implementation contract without deploying it.
   *
   * @param contractName Name of the contract to validate, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param opts Options for validations
   */
  function validateImplementation(string memory contractName, Options memory opts) internal {
    _validate(contractName, "", opts, false);
  }

  /**
   * @dev Validates a new implementation contract without deploying it.
   * Compares the reference contract to the new implementation contract to check for storage layout compatibility errors.
   *
   * @param contractName Name of the contract to validate, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param referenceContract Name of the reference contract to use for storage layout comparisons.
   *  If empty, uses the `@custom:oz-upgrades-from <reference>` annotation from the contract as the reference contract.
   * @param opts Options for validations
   */
  function validateUpgrade(string memory contractName, string memory referenceContract, Options memory opts) internal {
    _validate(contractName, referenceContract, opts, true);
  }

  /**
   * @dev Validates a new implementation contract without deploying it.
   * Uses the `@custom:oz-upgrades-from <reference>` annotation from the contract to use as the reference contract for storage layout comparisons.
   *
   * @param contractName Name of the contract to validate, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param opts Options for validations
   */
  function validateUpgrade(string memory contractName, Options memory opts) internal {
    validateUpgrade(contractName, "", opts);
  }

  /**
   * @dev Validates and deploys a new implementation contract, and returns its address.
   * Use this method to prepare an upgrade to be run from an admin address you do not control directly or cannot use from your deployment environment.
   *
   * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param referenceContract Name of the reference contract to use for storage layout comparisons.
   *  If empty, uses the `@custom:oz-upgrades-from <reference>` annotation from the contract as the reference contract.
   * @param opts Options for validations
   */
  function prepareUpgrade(string memory contractName, string memory referenceContract, Options memory opts) internal returns (address) {
    validateUpgrade(contractName, referenceContract, opts);
    return _deploy(contractName);
  }

  /**
   * @dev Validates and deploys a new implementation contract, and returns its address.
   * Uses the `@custom:oz-upgrades-from <reference>` annotation from the contract to use as the reference contract for storage layout comparisons.
   * Use this method to prepare an upgrade to be run from an admin address you do not control directly or cannot use from your deployment environment.
   *
   * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param opts Options for validations
   */
  function prepareUpgrade(string memory contractName, Options memory opts) internal returns (address) {
    return prepareUpgrade(contractName, "", opts);
  }

  /**
   * @dev Validates and deploys a new implementation contract, and returns its address.
   *
   * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param opts Options for validations
   */
  function deployImplementation(string memory contractName, Options memory opts) internal returns (address) {
    validateImplementation(contractName, opts);
    return _deploy(contractName);
  }

  function _deploy(string memory contractName) private returns (address) {
    bytes memory code = Vm(CHEATCODE_ADDRESS).getCode(contractName);
    return _deployFromBytecode(code);
  }

  function _deployFromBytecode(bytes memory bytecode) private returns (address) {
    address addr;
    assembly {
      addr := create(0, add(bytecode, 32), mload(bytecode))
    }
    return addr;
   }

  /**
   * @dev Deploys a UUPS proxy using the given contract as the implementation.
   *
   * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param data Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
   * @param opts Options for validations
   */
  function deployUUPSProxy(string memory contractName, bytes memory data, Options memory opts) internal returns (ERC1967Proxy) {
    address impl = deployImplementation(contractName, opts);
    return new ERC1967Proxy(impl, data);
  }

  /**
   * @dev Deploys a UUPS proxy using the given contract as the implementation.
   *
   * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param data Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
   */
  function deployUUPSProxy(string memory contractName, bytes memory data) internal returns (ERC1967Proxy) {
    Options memory opts;
    return deployUUPSProxy(contractName, data, opts);
  }

  /**
   * @dev Deploys a transparent proxy using the given contract as the implementation.
   *
   * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param initialOwner Address to set as the owner of the ProxyAdmin contract which gets deployed by the proxy
   * @param data Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
   * @param opts Options for validations
   */
  function deployTransparentProxy(string memory contractName, address initialOwner, bytes memory data, Options memory opts) internal returns (TransparentUpgradeableProxy) {
    address impl = deployImplementation(contractName, opts);
    return new TransparentUpgradeableProxy(impl, initialOwner, data);
  }

  /**
   * @dev Deploys a transparent proxy using the given contract as the implementation.
   *
   * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param initialOwner Address to set as the owner of the ProxyAdmin contract which gets deployed by the proxy
   * @param data Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
   */
  function deployTransparentProxy(string memory contractName, address initialOwner, bytes memory data) internal returns (TransparentUpgradeableProxy) {
    Options memory opts;
    return deployTransparentProxy(contractName, initialOwner, data, opts);
  }

  /**
   * @dev Deploys an upgradeable beacon using the given contract as the implementation.
   *
   * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param initialOwner Address to set as the owner of the UpgradeableBeacon contract which gets deployed
   * @param opts Options for validations
   */
  function deployBeacon(string memory contractName, address initialOwner, Options memory opts) internal returns (IBeacon) {
    address impl = deployImplementation(contractName, opts);
    return new UpgradeableBeacon(impl, initialOwner);
  }

  /**
   * @dev Deploys an upgradeable beacon using the given contract as the implementation.
   *
   * @param contractName Name of the contract to use as the implementation, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param initialOwner Address to set as the owner of the UpgradeableBeacon contract which gets deployed
   */
  function deployBeacon(string memory contractName, address initialOwner) internal returns (IBeacon) {
    Options memory opts;
    return deployBeacon(contractName, initialOwner, opts);
  }

  /**
   * @dev Deploys a beacon proxy using the given beacon and call data.
   *
   * @param beacon Address of the beacon to use
   * @param data Encoded call data of the initializer function to call during creation of the proxy, or empty if no initialization is required
   */
  function deployBeaconProxy(address beacon, bytes memory data) internal returns (BeaconProxy) {
    return new BeaconProxy(beacon, data);
  }

  /**
   * @dev Upgrades a proxy to a new implementation contract. Only supported for UUPS or transparent proxies.
   *
   * @param proxy Address of the proxy to upgrade
   * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no upgrade function is required
   * @param opts Options for validations
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
   * @param proxy Address of the proxy to upgrade
   * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no upgrade function is required
   */
  function upgradeProxy(address proxy, string memory contractName, bytes memory data) internal {
    Options memory opts;
    upgradeProxy(proxy, contractName, data, opts);
  }

  /**
   * @dev Upgrades a proxy to a new implementation contract. Only supported for UUPS or transparent proxies.
   * This function provides an additional `tryCaller` parameter to test an upgrade using an address that owns the proxy or its ProxyAdmin.
   *
   * @param proxy Address of the proxy to upgrade
   * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no upgrade function is required
   * @param opts Options for validations
   * @param tryCaller Address to use as the caller of the upgrade function.
   *  This uses Foundry's `prank` cheatcode to temporarily set the caller of the upgrade function to this address.
   */
  function upgradeProxy(address proxy, string memory contractName, bytes memory data, Options memory opts, address tryCaller) internal tryPrank(tryCaller) {
    upgradeProxy(proxy, contractName, data, opts);
  }

  /**
   * @dev Upgrades a proxy to a new implementation contract. Only supported for UUPS or transparent proxies.
   * This function provides an additional `tryCaller` parameter to test an upgrade using an address that owns the proxy or its ProxyAdmin.
   *
   * @param proxy Address of the proxy to upgrade
   * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param data Encoded call data of an arbitrary function to call during the upgrade process, or empty if no upgrade function is required
   * @param tryCaller Address to use as the caller of the upgrade function.
   *  This uses Foundry's `prank` cheatcode to temporarily set the caller of the upgrade function to this address.
   */
  function upgradeProxy(address proxy, string memory contractName, bytes memory data, address tryCaller) internal tryPrank(tryCaller) {
    Options memory opts;
    upgradeProxy(proxy, contractName, data, opts, tryCaller);
  }

  /**
   * @dev Upgrades a beacon to a new implementation contract.
   *
   * @param beacon Address of the beacon to upgrade
   * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param opts Options for validations
   */
  function upgradeBeacon(address beacon, string memory contractName, Options memory opts) internal {
    address newImpl = prepareUpgrade(contractName, opts);
    UpgradeableBeacon(beacon).upgradeTo(newImpl);
  }

  /**
   * @dev Upgrades a beacon to a new implementation contract.
   *
   * @param beacon Address of the beacon to upgrade
   * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   */
  function upgradeBeacon(address beacon, string memory contractName) internal {
    Options memory opts;
    upgradeBeacon(beacon, contractName, opts);
  }

  /**
   * @dev Upgrades a beacon to a new implementation contract.
   * This function provides an additional `tryCaller` parameter to test an upgrade using an address that owns the beacon.
   *
   * @param beacon Address of the beacon to upgrade
   * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param opts Options for validations
   * @param tryCaller Address to use as the caller of the upgrade function.
   *  This uses Foundry's `prank` cheatcode to temporarily set the caller of the upgrade function to this address.
   */
  function upgradeBeacon(address beacon, string memory contractName, Options memory opts, address tryCaller) internal tryPrank(tryCaller) {
    upgradeBeacon(beacon, contractName, opts);
  }

  /**
   * @dev Upgrades a beacon to a new implementation contract.
   * This function provides an additional `tryCaller` parameter to test an upgrade using an address that owns the beacon.
   *
   * @param beacon Address of the beacon to upgrade
   * @param contractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract"
   * @param tryCaller Address to use as the caller of the upgrade function.
   *  This uses Foundry's `prank` cheatcode to temporarily set the caller of the upgrade function to this address.
   */
  function upgradeBeacon(address beacon, string memory contractName, address tryCaller) internal tryPrank(tryCaller) {
    Options memory opts;
    upgradeBeacon(beacon, contractName, opts, tryCaller);
  }

  /**
   * @dev Gets the admin address of a transparent proxy according to its ERC1967 admin storage slot.
   *
   * @param proxy Address of a transparent proxy
   */
  function getAdminAddress(address proxy) internal view returns (address) {
    Vm vm = Vm(CHEATCODE_ADDRESS);

    bytes32 adminSlot = vm.load(proxy, ERC1967Utils.ADMIN_SLOT);
    return address(uint160(uint256(adminSlot)));
  }

  /**
   * @dev Gets the implementation address of a proxy according to its ERC1967 implementation storage slot.
   *
   * @param proxy Address of a transparent or UUPS proxy
   */
  function getImplementationAddress(address proxy) internal view returns (address) {
    Vm vm = Vm(CHEATCODE_ADDRESS);

    bytes32 implSlot = vm.load(proxy, ERC1967Utils.IMPLEMENTATION_SLOT);
    return address(uint160(uint256(implSlot)));
  }

  /**
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
}