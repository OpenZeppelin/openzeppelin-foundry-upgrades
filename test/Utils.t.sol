// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Utils} from "openzeppelin-foundry-upgrades/internal/Utils.sol";

contract UpgradesTest is Test {
    function testGetFullyQualifiedComponents_from_file() public {
        (string memory contractPath, string memory shortName) = Utils.getFullyQualifiedComponents("Greeter.sol", "out");

        assertEq(shortName, "Greeter");
        assertEq(contractPath, "test/contracts/Greeter.sol");
    }

    function testGetFullyQualifiedComponents_from_fileAndName() public {
        (string memory contractPath, string memory shortName) = Utils.getFullyQualifiedComponents(
            "MyContractFile.sol:MyContractName",
            "out"
        );

        assertEq(shortName, "MyContractName");
        assertEq(contractPath, "test/contracts/MyContractFile.sol");
    }

    function testGetFullyQualifiedComponents_from_artifact() public {
        (string memory contractPath, string memory shortName) = Utils.getFullyQualifiedComponents(
            "out/MyContractFile.sol/MyContractName.json",
            "out"
        );

        assertEq(shortName, "MyContractName");
        assertEq(contractPath, "test/contracts/MyContractFile.sol");
    }

    function testGetFullyQualifiedComponents_wrongNameFormat() public {
        Invoker c = new Invoker();
        try c.getFullyQualifiedComponents("Foo", "out") {
            fail();
        } catch Error(string memory reason) {
            assertEq(
                reason,
                "Contract name Foo must be in the format MyContract.sol:MyContract or MyContract.sol or out/MyContract.sol/MyContract.json"
            );
        }
    }

    function testGetFullyQualifiedComponents_invalidOutDir() public {
        Invoker c = new Invoker();
        try c.getFullyQualifiedComponents("Greeter.sol", "invalidoutdir") {
            fail();
        } catch {}
    }

    function testGetFullyQualifiedName_from_file() public {
        string memory fqName = Utils.getFullyQualifiedName("Greeter.sol", "out");

        assertEq(fqName, "test/contracts/Greeter.sol:Greeter");
    }

    function testGetFullyQualifiedName_from_fileAndName() public {
        string memory fqName = Utils.getFullyQualifiedName("MyContractFile.sol:MyContractName", "out");

        assertEq(fqName, "test/contracts/MyContractFile.sol:MyContractName");
    }

    function testGetFullyQualifiedName_from_artifact() public {
        string memory fqName = Utils.getFullyQualifiedName("out/MyContractFile.sol/MyContractName.json", "out");

        assertEq(fqName, "test/contracts/MyContractFile.sol:MyContractName");
    }

    function testGetFullyQualifiedName_wrongNameFormat() public {
        Invoker i = new Invoker();
        try i.getFullyQualifiedName("Foo", "out") {
            fail();
        } catch Error(string memory reason) {
            assertEq(
                reason,
                "Contract name Foo must be in the format MyContract.sol:MyContract or MyContract.sol or out/MyContract.sol/MyContract.json"
            );
        }
    }

    function testGetFullyQualifiedName_invalidOutDir() public {
        Invoker i = new Invoker();
        try i.getFullyQualifiedName("Greeter.sol", "invalidoutdir") {
            fail();
        } catch {}
    }

    function testGetOutDir() public {
        assertEq(Utils.getOutDir(), "out");
    }
}

contract Invoker {
    function getFullyQualifiedComponents(string memory contractName, string memory outDir) public view {
        Utils.getFullyQualifiedComponents(contractName, outDir);
    }

    function getFullyQualifiedName(string memory contractName, string memory outDir) public view {
        Utils.getFullyQualifiedName(contractName, outDir);
    }
}
