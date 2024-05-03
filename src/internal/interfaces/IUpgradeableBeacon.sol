// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUpgradeableBeacon {
    function upgradeTo(address) external;
}
