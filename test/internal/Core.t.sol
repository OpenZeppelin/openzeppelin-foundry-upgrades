// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Options} from "openzeppelin-foundry-upgrades/Options.sol";
import {Core} from "openzeppelin-foundry-upgrades/internal/Core.sol";
import {Versions} from "openzeppelin-foundry-upgrades/internal/Versions.sol";
import {Strings} from "../utils/Strings.sol";

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

    function testBuildValidateCommand() public view {
        Options memory opts;

        string memory commandString = Strings.joinWithSpace(Core.buildValidateCommand("Greeter.sol", opts, false));
        assertEq(
            commandString,
            string.concat(
                "npx @openzeppelin/upgrades-core@",
                Versions.UPGRADES_CORE,
                " validate out/build-info --contract test/contracts/Greeter.sol:Greeter"
            )
        );
    }

    function testBuildValidateCommandExcludes() public view {
        Options memory opts;
        opts.exclude = new string[](2);
        opts.exclude[0] = "test/contracts/**/{Foo,Bar}.sol";
        opts.exclude[1] = "test/contracts/helpers/**.sol";

        string memory commandString = Strings.joinWithSpace(Core.buildValidateCommand("Greeter.sol", opts, false));
        assertEq(
            commandString,
            string.concat(
                "npx @openzeppelin/upgrades-core@",
                Versions.UPGRADES_CORE,
                ' validate out/build-info --contract test/contracts/Greeter.sol:Greeter --exclude "test/contracts/**/{Foo,Bar}.sol" --exclude "test/contracts/helpers/**.sol"'
            )
        );
    }
}
