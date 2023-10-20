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

struct Options {
  string outDir;
}

library Upgrades {
  address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

  function _validate(string memory contractName, string memory referenceContract, Options memory opts, bool requireReference) private {
    // TODO get defaults from foundry.toml
    string memory outDir = opts.outDir;
    if (bytes(outDir).length == 0) {
      outDir = "out";
    }

    string[] memory inputs;

    uint8 inputLength = 6;
    if (bytes(referenceContract).length != 0) {
      inputLength += 2;
    }
    if (requireReference) {
      inputLength += 1;
    }
    inputs = new string[](inputLength);

    uint8 i = 0;
    inputs[i++] = "npx";
    inputs[i++] = "@openzeppelin/upgrades-core";
    inputs[i++] = "validate";
    inputs[i++] = string.concat(outDir, "/build-info");
    inputs[i++] = "--contract";
    inputs[i++] = contractName;
    if (bytes(referenceContract).length != 0) {
      inputs[i++] = "--reference";
      inputs[i++] = referenceContract;
    }
    if (requireReference) {
      inputs[i++] = "--requireReference";
    }

    // TODO support contract name without .sol extension
    // TODO pass in validation options from environment variables

    bytes memory res = Vm(CHEATCODE_ADDRESS).ffi(inputs);

    // if last 7 chars is "SUCCESS"
    if (res[res.length - 7] == "S" && res[res.length - 6] == "U" && res[res.length - 5] == "C" && res[res.length - 4] == "C" && res[res.length - 3] == "E" && res[res.length - 2] == "S" && res[res.length - 1] == "S") {
      return;
    }
    revert(string.concat("Upgrade safety validation failed: ", string(res)));
  }

  function validateImplementation(string memory contractName, Options memory opts) internal {
    _validate(contractName, "", opts, false);
  }

  function validateUpgrade(string memory contractName, string memory referenceContract, Options memory opts) internal {
    _validate(contractName, referenceContract, opts, true);
  }

  function validateUpgrade(string memory contractName, Options memory opts) internal {
    validateUpgrade(contractName, "", opts);
  }

  function prepareUpgrade(string memory contractName, string memory referenceContract, Options memory opts) internal returns (address) {
    validateUpgrade(contractName, referenceContract, opts);
    return _deploy(contractName);
  }

  function prepareUpgrade(string memory contractName, Options memory opts) internal returns (address) {
    return prepareUpgrade(contractName, "", opts);
  }

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

  function deployUUPSProxy(string memory contractName, bytes memory data, Options memory opts) internal returns (ERC1967Proxy) {
    address impl = deployImplementation(contractName, opts);
    return new ERC1967Proxy(impl, data);
  }

  function deployUUPSProxy(string memory contractName, bytes memory data) internal returns (ERC1967Proxy) {
    Options memory opts;
    return deployUUPSProxy(contractName, data, opts);
  }

  function deployTransparentProxy(string memory contractName, address initialOwner, bytes memory data, Options memory opts) internal returns (TransparentUpgradeableProxy) {
    address impl = deployImplementation(contractName, opts);
    return new TransparentUpgradeableProxy(impl, initialOwner, data);
  }

  function deployTransparentProxy(string memory contractName, address initialOwner, bytes memory data) internal returns (TransparentUpgradeableProxy) {
    Options memory opts;
    return deployTransparentProxy(contractName, initialOwner, data, opts);
  }

  function deployBeacon(string memory contractName, address initialOwner, Options memory opts) internal returns (IBeacon) {
    address impl = deployImplementation(contractName, opts);
    return new UpgradeableBeacon(impl, initialOwner);
  }

  function deployBeacon(string memory contractName, address initialOwner) internal returns (IBeacon) {
    Options memory opts;
    return deployBeacon(contractName, initialOwner, opts);
  }

  function deployBeaconProxy(address beacon, bytes memory data) internal returns (BeaconProxy) {
    return new BeaconProxy(beacon, data);
  }

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

  function upgradeProxy(address proxy, string memory contractName, bytes memory data) internal {
    Options memory opts;
    upgradeProxy(proxy, contractName, data, opts);
  }

  function upgradeProxy(address proxy, string memory contractName, bytes memory data, Options memory opts, address tryCaller) internal tryPrank(tryCaller) {
    upgradeProxy(proxy, contractName, data, opts);
  }

  function upgradeProxy(address proxy, string memory contractName, bytes memory data, address tryCaller) internal tryPrank(tryCaller) {
    Options memory opts;
    upgradeProxy(proxy, contractName, data, opts, tryCaller);
  }

  function upgradeBeacon(address beacon, string memory contractName, Options memory opts) internal {
    address newImpl = prepareUpgrade(contractName, opts);
    UpgradeableBeacon(beacon).upgradeTo(newImpl);
  }

  function upgradeBeacon(address beacon, string memory contractName) internal {
    Options memory opts;
    upgradeBeacon(beacon, contractName, opts);
  }

  function upgradeBeacon(address beacon, string memory contractName, Options memory opts, address tryCaller) internal tryPrank(tryCaller) {
    upgradeBeacon(beacon, contractName, opts);
  }

  function upgradeBeacon(address beacon, string memory contractName, address tryCaller) internal tryPrank(tryCaller) {
    Options memory opts;
    upgradeBeacon(beacon, contractName, opts, tryCaller);
  }

  function getAdminAddress(address proxy) internal view returns (address) {
    Vm vm = Vm(CHEATCODE_ADDRESS);

    bytes32 adminSlot = vm.load(proxy, ERC1967Utils.ADMIN_SLOT);
    return address(uint160(uint256(adminSlot)));
  }

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