// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {Utils} from "openzeppelin-foundry-upgrades/internal/Utils.sol";

contract UpgradesTest is Test {
    function testGetFullyQualifiedNameComponents_from_file() public {
        (string memory contractPath, string memory shortName) = Utils.getFullyQualifiedNameComponents("Greeter.sol", "");

        assertEq(shortName, "Greeter");
        assertEq(contractPath, "test/contracts/Greeter.sol");
    }

    function testGetFullyQualifiedNameComponents_from_fileAndName() public {
        (string memory contractPath, string memory shortName) = Utils.getFullyQualifiedNameComponents("MyContractFile.sol:MyContractName", "");

        assertEq(shortName, "MyContractName");
        assertEq(contractPath, "test/contracts/MyContractFile.sol");
    }

    function testGetFullyQualifiedNameComponents_from_artifact() public {
        (string memory contractPath, string memory shortName) = Utils.getFullyQualifiedNameComponents("out/MyContractFile.sol/MyContractName.json", "");

        assertEq(shortName, "MyContractName");
        assertEq(contractPath, "test/contracts/MyContractFile.sol");
    }

    function testGetFullyQualifiedName_from_file() public {
        string memory fqName = Utils.getFullyQualifiedName("Greeter.sol", "");

        assertEq(fqName, "test/contracts/Greeter.sol:Greeter");
    }

    function testGetFullyQualifiedName_from_fileAndName() public {
        string memory fqName = Utils.getFullyQualifiedName("MyContractFile.sol:MyContractName", "");

        assertEq(fqName, "test/contracts/MyContractFile.sol:MyContractName");
    }

    function testGetFullyQualifiedName_from_artifact() public {
        string memory fqName = Utils.getFullyQualifiedName("out/MyContractFile.sol/MyContractName.json", "");

        assertEq(fqName, "test/contracts/MyContractFile.sol:MyContractName");
    }

    function testGetOutDirWithDefaults() public {
        assertEq(Utils.getOutDirWithDefaults(""), "out");
        assertEq(Utils.getOutDirWithDefaults("out"), "out");
        assertEq(Utils.getOutDirWithDefaults("foo"), "foo");
    }
}
