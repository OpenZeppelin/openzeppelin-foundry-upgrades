// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MyContract} from "./contracts/MyContract.sol";

/**
 * @dev Tests for the Upgrades library.
 */
contract UpgradesTest is Test {
    function testValidate() public {
        Options memory opts;
        opts.referenceBuildInfoDirs = new string[](1);
        opts.referenceBuildInfoDirs[0] = "test_artifacts/build-info-v1";

        Upgrades.validateUpgrade(
            "MyContract.sol",
            opts
        );
    }
}
