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

library Upgrades {
  address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

  function deployImplementation(string memory contractName) internal returns (address) {
    bytes memory code = Vm(CHEATCODE_ADDRESS).getCode(contractName);
    return deployFromBytecode(code);
  }

  function deployFromBytecode(bytes memory bytecode) private returns (address) {
    address addr;
    assembly {
      addr := create(0, add(bytecode, 32), mload(bytecode))
    }
    return addr;
   }

  function deployUUPSProxy(string memory contractName, bytes memory data) internal returns (ERC1967Proxy) {
    address impl = deployImplementation(contractName);
    return new ERC1967Proxy(impl, data);
  }

  function deployTransparentProxy(string memory contractName, address initialOwner, bytes memory data) internal returns (TransparentUpgradeableProxy) {
    address impl = deployImplementation(contractName);
    return new TransparentUpgradeableProxy(impl, initialOwner, data);
  }

  function deployBeacon(string memory contractName, address initialOwner) internal returns (IBeacon) {
    address impl = deployImplementation(contractName);
    return new UpgradeableBeacon(impl, initialOwner);
  }

  function deployBeaconProxy(address beacon, bytes memory data) internal returns (BeaconProxy) {
    return new BeaconProxy(beacon, data);
  }

  function upgradeProxy(address proxy, string memory contractName, bytes memory data) internal  {
    address newImpl = deployImplementation(contractName);

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

  function upgradeProxy(address proxy, string memory contractName, bytes memory data, address tryCaller) internal tryPrank(tryCaller) {
    upgradeProxy(proxy, contractName, data);
  }

  function upgradeBeacon(address beacon, string memory contractName) internal {
    address newImpl = deployImplementation(contractName);
    UpgradeableBeacon(beacon).upgradeTo(newImpl);
  }

  function upgradeBeacon(address beacon, string memory contractName, address tryCaller) internal tryPrank(tryCaller) {
    upgradeBeacon(beacon, contractName);
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