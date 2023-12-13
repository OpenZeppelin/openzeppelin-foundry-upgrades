// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ITransparentUpgradeableProxy, TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {strings} from "solidity-stringutils/strings.sol";

import {Versions} from "./Versions.sol";

/**
 * @dev Library for deploying and managing upgradeable contracts from Forge scripts or tests.
 */
library Defender {
    
    address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function deployContract(
        string memory contractName
    ) internal {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        console.log("Deploying ", contractName);

        string memory shortName = _toShortName(contractName);
        console.log("Short name: ", shortName);

        string memory contractFileName = _toContractFileName(contractName);
        console.log("Contract file name: ", contractFileName);

        // get json file at out/contractFileName/shortName
        // concat projectRoot() in front
        string memory artifactPath = string.concat(vm.projectRoot(), "/out/", contractFileName, "/", shortName, ".json");

        console.log("artifactPath ", artifactPath);



        // get ast.absolutePath from json
        string memory json = vm.readFile(artifactPath);
        // console.log(json);

        bytes memory absolutePath = vm.parseJson(json, ".ast.absolutePath");
        console.log("absolutePath ", string(absolutePath));
    }

    using strings for *;

    function _toContractFileName(string memory contractName) private pure returns (string memory) {
        strings.slice memory name = contractName.toSlice();
        if (name.endsWith(".sol".toSlice())) {
            return name.toString();
        } else if (name.count(":".toSlice()) == 1) {
            return name.split(":".toSlice()).toString();
        } else {
            // TODO support artifact file name
            revert(
                string.concat(
                    "Contract name ",
                    contractName,
                    " must be in the format MyContract.sol:MyContract or MyContract.sol"
                )
            );
        }

    }

    function _toShortName(string memory contractName) private pure returns (string memory) {
        strings.slice memory name = contractName.toSlice();
        if (name.endsWith(".sol".toSlice())) {
            return name.until(".sol".toSlice()).toString();
        } else if (name.count(":".toSlice()) == 1) {
            // TODO lookup artifact file and return fully qualified name to support identical contract names in different files
            name.split(":".toSlice());
            return name.split(":".toSlice()).toString();
        } else {
            // TODO support artifact file name
            revert(
                string.concat(
                    "Contract name ",
                    contractName,
                    " must be in the format MyContract.sol:MyContract or MyContract.sol"
                )
            );
        }
    }

}
