// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import "forge-std/Vm.sol";
import {console} from "forge-std/Console.sol";

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

  function upgradeProxy(address proxy, bytes memory newImplCreationCode, address owner, bytes memory data) internal broadcast(owner) {
    address newImpl = deployImplementation(newImplCreationCode);

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

  function upgradeBeacon(address beacon, bytes memory newImplCreationCode, address owner) internal broadcast(owner) {
    address newImpl = deployImplementation(newImplCreationCode);

    UpgradeableBeacon(beacon).upgradeTo(newImpl);
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
    console.log('msg.sender in Upgrades is %s', msg.sender);
    console.log('deployer is ', deployer);

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