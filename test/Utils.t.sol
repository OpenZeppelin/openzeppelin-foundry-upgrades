// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

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

    function testGetFullyQualifiedNameComponents_wrongNameFormat() public {
        Caller c = new Caller();
        try c.getFullyQualifiedNameComponents("Foo", "") {
            fail();
        } catch Error(string memory reason) {
            assertEq(reason, "Contract name Foo must be in the format MyContract.sol:MyContract or MyContract.sol or out/MyContract.sol/MyContract.json");
        }
    }

    function testGetFullyQualifiedNameComponents_invalidOutDir() public {
        Caller c = new Caller();
        try c.getFullyQualifiedNameComponents("Greeter.sol", "invalidoutdir") {
            fail();
        } catch {
        }
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

    function testGetFullyQualifiedName_wrongNameFormat() public {
        Caller c = new Caller();
        try c.getFullyQualifiedName("Foo", "") {
            fail();
        } catch Error(string memory reason) {
            assertEq(reason, "Contract name Foo must be in the format MyContract.sol:MyContract or MyContract.sol or out/MyContract.sol/MyContract.json");
        }
    }

    function testGetFullyQualifiedName_invalidOutDir() public {
        Caller c = new Caller();
        try c.getFullyQualifiedNameComponents("Greeter.sol", "invalidoutdir") {
            fail();
        } catch {
        }
    }

    function testGetOutDirWithDefaults() public {
        assertEq(Utils.getOutDirWithDefaults(""), "out");
        assertEq(Utils.getOutDirWithDefaults("out"), "out");
        assertEq(Utils.getOutDirWithDefaults("foo"), "foo");
    }
}

contract Caller {
    function getFullyQualifiedName(string memory contractName, string memory outDir) public view {
        Utils.getFullyQualifiedName(contractName, outDir);
    }

    function getFullyQualifiedNameComponents(string memory contractName, string memory outDir) public view {
        Utils.getFullyQualifiedNameComponents(contractName, outDir);
    }
}
