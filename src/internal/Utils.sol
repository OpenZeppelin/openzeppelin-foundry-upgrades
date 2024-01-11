// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {strings} from "solidity-stringutils/strings.sol";

struct ContractInfo {
    /**
     * Contract path, e.g. "src/MyContract.sol"
     */
    string contractPath;
    /**
     * Contract short name, e.g. "MyContract"
     */
    string shortName;
    /**
     * Bytecode string from the compiled artifact
     */
    string bytecode;
    /**
     * License identifier from the compiled artifact
     */
    string license;
}

/**
 * @dev Internal helper methods used by Upgrades and Defender libraries.
 */
library Utils {
    address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    /**
     * @dev Gets the fully qualified name of a contract.
     *
     * @param contractName Contract name in the format "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param outDir Foundry output directory to search in if contractName is not an artifact path
     * @return Fully qualified name of the contract, e.g. "src/MyContract.sol:MyContract"
     */
    function getFullyQualifiedName(
        string memory contractName,
        string memory outDir
    ) internal view returns (string memory) {
        ContractInfo memory info = getContractInfo(contractName, outDir);
        return string.concat(info.contractPath, ":", info.shortName);
    }

    /**
     * @dev Gets information about a contract from its Foundry artifact.
     *
     * @param contractName Contract name in the format "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param outDir Foundry output directory to search in if contractName is not an artifact path
     * @return ContractInfo struct containing information about the contract
     */
    function getContractInfo(
        string memory contractName,
        string memory outDir
    ) internal view returns (ContractInfo memory) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        ContractInfo memory info;

        info.shortName = _toShortName(contractName);

        string memory fileName = _toFileName(contractName);

        string memory artifactPath = string.concat(
            vm.projectRoot(),
            "/",
            outDir,
            "/",
            fileName,
            "/",
            info.shortName,
            ".json"
        );
        string memory artifactJson = vm.readFile(artifactPath);

        info.contractPath = vm.parseJsonString(artifactJson, ".ast.absolutePath");
        info.license = vm.parseJsonString(artifactJson, ".ast.license");
        info.bytecode = vm.parseJsonString(artifactJson, ".bytecode.object");

        return info;
    }

    using strings for *;

    /**
     * Gets the path to the build-info file that contains the given bytecode.
     *
     * @param bytecode Contract bytecode in string format, starting with 0x
     * @param contractName Contract name to display in error message if build-info file is not found
     * @param outDir Foundry output directory that contains a build-info directory
     * @return The path to the build-info file that contains the given bytecode
     */
    function getBuildInfoFile(
        string memory bytecode,
        string memory contractName,
        string memory outDir
    ) internal returns (string memory) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        string memory trimmedBytecode = bytecode.toSlice().beyond("0x".toSlice()).toString();

        string[] memory inputs = new string[](4);
        inputs[0] = "grep";
        inputs[1] = "-rl";
        inputs[2] = string.concat('"', trimmedBytecode, '"');
        inputs[3] = string.concat(outDir, "/build-info");

        string memory result = string(vm.ffi(inputs));

        if (!result.toSlice().endsWith(".json".toSlice())) {
            revert(string.concat("Could not find build-info file with bytecode for contract ", contractName));
        }

        return result;
    }

    /**
     * @dev Gets the output directory from the FOUNDRY_OUT environment variable, or defaults to "out" if not set.
     */
    function getOutDir() internal returns (string memory) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        string memory defaultOutDir = "out";
        return vm.envOr("FOUNDRY_OUT", defaultOutDir);
    }

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
