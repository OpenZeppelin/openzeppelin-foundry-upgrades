// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Core} from "openzeppelin-foundry-upgrades/internal/Core.sol";

import {UpgradeInterfaceVersionString, UpgradeInterfaceVersionNoGetter, UpgradeInterfaceVersionEmpty, UpgradeInterfaceVersionInteger, UpgradeInterfaceVersionVoid} from "../contracts/UpgradeInterfaceVersions.sol";

/**
 * @dev Tests the Core internal library.
 */
contract CoreTest is Test {
    function testGetUpgradeInterfaceVersion_string() public {
        UpgradeInterfaceVersionString u = new UpgradeInterfaceVersionString();
        assertEq(Core.getUpgradeInterfaceVersion(address(u)), "5.0.0");
    }

    function testGetUpgradeInterfaceVersion_noGetter() public {
        UpgradeInterfaceVersionNoGetter u = new UpgradeInterfaceVersionNoGetter();
        assertEq(Core.getUpgradeInterfaceVersion(address(u)), "");
    }

    function testGetUpgradeInterfaceVersion_empty() public {
        UpgradeInterfaceVersionEmpty u = new UpgradeInterfaceVersionEmpty();
        assertEq(Core.getUpgradeInterfaceVersion(address(u)), "");
    }

    function testGetUpgradeInterfaceVersion_integer() public {
        UpgradeInterfaceVersionInteger u = new UpgradeInterfaceVersionInteger();
        assertEq(Core.getUpgradeInterfaceVersion(address(u)), "");
    }

    function testGetUpgradeInterfaceVersion_void() public {
        UpgradeInterfaceVersionVoid u = new UpgradeInterfaceVersionVoid();
        assertEq(Core.getUpgradeInterfaceVersion(address(u)), "");
    }
}
