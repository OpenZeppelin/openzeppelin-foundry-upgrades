// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev  Use the functions in this interface based on the `UPGRADE_INTERFACE_VERSION` of the contract.
 * If the `UPGRADE_INTERFACE_VERSION` getter is missing, both `upgrade(address,address)`
 * and `upgradeAndCall(address,address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
 * while `upgradeAndCall` will invoke the `receive` function if the second argument is the empty byte string.
 * If the getter returns `"5.0.0"`, only `upgradeAndCall(address,address,bytes)` is present, and the second argument must
 * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
 * during an upgrade.
 */
interface IProxyAdmin {
    function upgrade(address, address) external;

    function upgradeAndCall(address, address, bytes memory) external payable;
}