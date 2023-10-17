// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ITransparentUpgradeableProxy, TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {Vm} from "forge-std/Vm.sol";

library Upgrades {
  address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

  function deployImplementation(bytes memory creationCode) internal returns (address) {
    return deployFromBytecode(creationCode);
  }

  function deployFromBytecode(bytes memory bytecode) private returns (address) {
    address addr;
    assembly {
      addr := create(0, add(bytecode, 32), mload(bytecode))
    }
    return addr;
   }

  function deployUUPSProxy(bytes memory implCreationCode, bytes memory data) internal returns (ERC1967Proxy) {
    address impl = deployImplementation(implCreationCode);
    return new ERC1967Proxy(impl, data);
  }

  function deployTransparentProxy(bytes memory implCreationCode, address initialOwner, bytes memory data) internal returns (TransparentUpgradeableProxy) {
    address impl = deployImplementation(implCreationCode);
    return new TransparentUpgradeableProxy(impl, initialOwner, data);
  }

  function deployBeacon(bytes memory implCreationCode, address initialOwner) internal returns (IBeacon) {
    address impl = deployImplementation(implCreationCode);
    return new UpgradeableBeacon(impl, initialOwner);
  }

  function deployBeaconProxy(address beacon, bytes memory data) internal returns (BeaconProxy) {
    return new BeaconProxy(beacon, data);
  }

  function upgradeProxy(address proxy, address newImpl, address owner, bytes memory data) internal broadcast(owner) {
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

  function upgradeProxy(address proxy, bytes memory newImplCreationCode, address owner, bytes memory data) internal {
    address newImpl = deployImplementation(newImplCreationCode);
    upgradeProxy(proxy, newImpl, owner, data);
  }

  function upgradeBeacon(address beacon, address newImpl, address owner) internal broadcast(owner) {
    UpgradeableBeacon(beacon).upgradeTo(newImpl);
  }

  function upgradeBeacon(address beacon, bytes memory newImplCreationCode, address owner) internal {
    address newImpl = deployImplementation(newImplCreationCode);
    upgradeBeacon(beacon, newImpl, owner);
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

  modifier broadcast(address deployer) {
    Vm vm = Vm(CHEATCODE_ADDRESS);

    bool wasBroadcasting = false;
    try vm.stopBroadcast() {
      wasBroadcasting = true;
    } catch {
      // ignore
    }

    vm.startBroadcast(deployer);
    _;
    vm.stopBroadcast();
    
    if (wasBroadcasting) {
      vm.startBroadcast(msg.sender);
    }
  }
}