// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUpgradeInferfaceVersion {
    /**
     * Gets the upgrade interface version. For versions of OpenZeppelin Contracts below 5.0.0, this getter does not exist and calling it will revert.
     */
    // solhint-disable-next-line func-name-mixedcase
    function UPGRADE_INTERFACE_VERSION() external pure returns (string memory);
}
