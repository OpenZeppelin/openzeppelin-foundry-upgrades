// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Use the functions in this interface based on the `UPGRADE_INTERFACE_VERSION` of the contract.
 * If the `UPGRADE_INTERFACE_VERSION` getter is missing, both `upgradeTo(address)`
 * and `upgradeToAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
 * while `upgradeToAndCall` will invoke the `receive` function if the second argument is the empty byte string.
 * If the getter returns `"5.0.0"`, only `upgradeToAndCall(address,bytes)` is present, and the second argument must
 * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
 * during an upgrade.
 */
interface IUpgradeableProxy {
    function upgradeTo(address) external;

    function upgradeToAndCall(address, bytes memory) external payable;
}
