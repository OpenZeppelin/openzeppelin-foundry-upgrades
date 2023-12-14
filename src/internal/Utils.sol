// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {strings} from "solidity-stringutils/strings.sol";

/**
 * @dev Internal helper methods used by Upgrades and Defender libraries.
 */
library Utils {
    address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    /**
     * @dev Gets the fully qualified name of a contract.
     *
     * @param contractName Contract name in the format "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param outDir Foundry output directory to search in if contractName is not an artifact path. Defaults to "out" if empty.
     * @return Fully qualified name of the contract, e.g. "src/MyContract.sol:MyContract"
     */
    function getFullyQualifiedName(
        string memory contractName,
        string memory outDir
    ) internal view returns (string memory) {
        (string memory contractPath, string memory shortName) = getFullyQualifiedComponents(contractName, outDir);
        return string.concat(contractPath, ":", shortName);
    }

    /**
     * @dev Gets the short name and contract path as components of a fully qualified contract name.
     *
     * @param contractName Contract name in the format "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param outDir Foundry output directory to search in if contractName is not an artifact path. Defaults to "out" if empty.
     * @return contractPath Contract path, e.g. "src/MyContract.sol"
     * @return shortName Contract short name, e.g. "MyContract"
     */
    function getFullyQualifiedComponents(
        string memory contractName,
        string memory outDir
    ) internal view returns (string memory contractPath, string memory shortName) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        shortName = _toShortName(contractName);

        string memory fileName = _toFileName(contractName);

        string memory artifactPath = string.concat(
            vm.projectRoot(),
            "/",
            getOutDirWithDefaults(outDir),
            "/",
            fileName,
            "/",
            shortName,
            ".json"
        );
        string memory artifactJson = vm.readFile(artifactPath);

        contractPath = vm.parseJsonString(artifactJson, ".ast.absolutePath");
    }

    /**
     * @dev Gets the output directory to search for artifacts in.
     *
     * @param outDir Override for the output directory. Defaults to "out" if empty.
     */
    function getOutDirWithDefaults(string memory outDir) internal pure returns (string memory) {
        // TODO get defaults from foundry.toml
        string memory result = outDir;
        if (bytes(outDir).length == 0) {
            result = "out";
        }
        return result;
    }

    using strings for *;

    function _split(
        strings.slice memory inputSlice,
        strings.slice memory delimSlice
    ) private pure returns (string[] memory) {
        string[] memory parts = new string[](inputSlice.count(delimSlice) + 1);
        for (uint i = 0; i < parts.length; i++) {
            parts[i] = inputSlice.split(delimSlice).toString();
        }
        return parts;
    }

    function _toFileName(string memory contractName) private pure returns (string memory) {
        strings.slice memory name = contractName.toSlice();
        if (name.endsWith(".sol".toSlice())) {
            return name.toString();
        } else if (name.count(":".toSlice()) == 1) {
            return name.split(":".toSlice()).toString();
        } else {
            if (name.endsWith(".json".toSlice())) {
                string[] memory parts = _split(name, "/".toSlice());
                if (parts.length > 1) {
                    return parts[parts.length - 2];
                }
            }

            revert(
                string.concat(
                    "Contract name ",
                    contractName,
                    " must be in the format MyContract.sol:MyContract or MyContract.sol or out/MyContract.sol/MyContract.json"
                )
            );
        }
    }

    function _toShortName(string memory contractName) private pure returns (string memory) {
        strings.slice memory name = contractName.toSlice();
        if (name.endsWith(".sol".toSlice())) {
            return name.until(".sol".toSlice()).toString();
        } else if (name.count(":".toSlice()) == 1) {
            name.split(":".toSlice());
            return name.split(":".toSlice()).toString();
        } else if (name.endsWith(".json".toSlice())) {
            string[] memory parts = _split(name, "/".toSlice());
            string memory jsonName = parts[parts.length - 1];
            return jsonName.toSlice().until(".json".toSlice()).toString();
        } else {
            revert(
                string.concat(
                    "Contract name ",
                    contractName,
                    " must be in the format MyContract.sol:MyContract or MyContract.sol or out/MyContract.sol/MyContract.json"
                )
            );
        }
    }
}
