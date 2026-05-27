// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from "forge-std/Vm.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {StringFinder} from "./StringFinder.sol";

struct ContractInfo {
    /*
     * Contract path, e.g. "src/MyContract.sol"
     */
    string contractPath;
    /*
     * Contract short name, e.g. "MyContract"
     */
    string shortName;
    /*
     * License identifier from the compiled artifact. Empty if not found.
     */
    string license;
    /*
     * keccak256 hash of the source code from metadata
     */
    string sourceCodeHash;
    /*
     * Artifact file path e.g. the path of the file 'out/MyContract.sol/MyContract.json'
     */
    string artifactPath;
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
    function getFullyQualifiedName(string memory contractName, string memory outDir) internal returns (string memory) {
        ContractInfo memory info = getContractInfo(contractName, outDir);
        return string(abi.encodePacked(info.contractPath, ":", info.shortName));
    }

    /**
     * @dev Gets information about a contract from its Foundry artifact.
     *
     * @param contractName Contract name in the format "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param outDir Foundry output directory to search in if contractName is not an artifact path
     * @return ContractInfo struct containing information about the contract
     */
    function getContractInfo(string memory contractName, string memory outDir) internal returns (ContractInfo memory) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        ContractInfo memory info;

        info.shortName = _toShortName(contractName);

        string memory fileName = _toFileName(contractName);

        // Try direct path first (original behavior)
        string memory artifactPath = string(
            abi.encodePacked(vm.projectRoot(), "/", outDir, "/", fileName, "/", info.shortName, ".json")
        );

        try vm.readFile(artifactPath) returns (string memory artifactJson) {
            return _processArtifact(vm, info, artifactPath, artifactJson);
        } catch {
            artifactPath = _findArtifactByName(vm, outDir, info.shortName);
            string memory artifactJson = vm.readFile(artifactPath);
            return _processArtifact(vm, info, artifactPath, artifactJson);
        }
    }

    /**
     * @dev Processes artifact JSON and populates ContractInfo.
     */
    function _processArtifact(
        Vm vm,
        ContractInfo memory info,
        string memory artifactPath,
        string memory artifactJson
    ) private view returns (ContractInfo memory) {
        info.artifactPath = artifactPath;

        if (!vm.keyExistsJson(artifactJson, ".ast")) {
            revert(
                string(
                    abi.encodePacked(
                        "Could not find AST in artifact ",
                        artifactPath,
                        ". Set `ast = true` in foundry.toml"
                    )
                )
            );
        }

        string memory absolutePath = vm.parseJsonString(artifactJson, ".ast.absolutePath");

        // For Hardhat 3, remove "project/" prefix to get user source name
        // Hardhat 3 uses canonical names (project/contracts/...) but CLI expects user names (contracts/...)
        bool isHH3Format = vm.keyExistsJson(artifactJson, "._format") &&
            Strings.equal(vm.parseJsonString(artifactJson, "._format"), "hh3-artifact-1");

        if (isHH3Format && StringFinder.startsWith(absolutePath, "project/")) {
            info.contractPath = vm.replace(absolutePath, "project/", "");
        } else {
            info.contractPath = absolutePath;
        }

        if (vm.keyExistsJson(artifactJson, ".ast.license")) {
            info.license = vm.parseJsonString(artifactJson, ".ast.license");
        }
        info.sourceCodeHash = vm.parseJsonString(
            artifactJson,
            string(abi.encodePacked(".metadata.sources.['", absolutePath, "'].keccak256"))
        );

        return info;
    }

    /**
     * @dev Fallback artifact lookup for when the direct path doesn't exist. Searches for
     * `<shortName>.json` anywhere under outDir. Needed for layouts like Hardhat's, where
     * artifacts are nested by source path (e.g. `<outDir>/contracts/foo/Bar.sol/Bar.json`)
     * rather than Foundry's flat `<outDir>/Bar.sol/Bar.json`. Reverts on zero or multiple
     * matches.
     * @return Absolute path to the matching artifact.
     */
    function _findArtifactByName(Vm vm, string memory outDir, string memory shortName) private returns (string memory) {
        // inputs are space-joined unquoted into one bash command — quote any operand
        // that could contain spaces or other shell-special characters.
        string[] memory inputs = new string[](6);
        inputs[0] = "find";
        inputs[1] = string(abi.encodePacked('"', outDir, '"'));
        inputs[2] = "-type";
        inputs[3] = "f";
        inputs[4] = "-name";
        inputs[5] = string(abi.encodePacked(shortName, ".json"));

        Vm.FfiResult memory result = runAsBashCommand(inputs);
        string memory stdout = string(result.stdout);

        // Check for no matches (empty output or find failure)
        if (result.exitCode != 0 || bytes(stdout).length == 0) {
            revert(
                string(abi.encodePacked("Could not find artifact for contract ", shortName, " in directory ", outDir))
            );
        }

        // Split by newlines and filter empty entries
        string[] memory lines = vm.split(stdout, "\n");
        uint256 matchCount = 0;
        string memory firstMatch;

        for (uint256 i = 0; i < lines.length; i++) {
            if (bytes(lines[i]).length > 0) {
                if (matchCount == 0) {
                    firstMatch = lines[i];
                }
                matchCount++;
            }
        }

        // Fail on zero matches
        if (matchCount == 0) {
            revert(
                string(abi.encodePacked("Could not find artifact for contract ", shortName, " in directory ", outDir))
            );
        }

        // Fail on multiple matches to avoid ambiguity
        if (matchCount > 1) {
            revert(
                string(
                    abi.encodePacked(
                        "Found multiple artifacts for contract ",
                        shortName,
                        " in directory ",
                        outDir,
                        ". Specify the Solidity file name and the contract name in the format 'MyContract.sol:MyContract' or use the artifact path."
                    )
                )
            );
        }

        return string(abi.encodePacked(vm.projectRoot(), "/", firstMatch));
    }

    using StringFinder for string;

    /**
     * @dev Gets the build info directory. Detects the environment by checking if outDir
     * starts with "artifacts/contracts" (Hardhat convention).
     *
     * @param outDir Foundry output directory (e.g., "out" or "artifacts/contracts")
     * @return The path to the build-info directory
     */
    function getBuildInfoDir(string memory outDir) internal pure returns (string memory) {
        // Normalize outDir by removing trailing slash if present
        string memory normalizedOutDir = outDir;
        if (outDir.endsWith("/")) {
            // Remove trailing slash by taking substring
            bytes memory outDirBytes = bytes(outDir);
            bytes memory trimmed = new bytes(outDirBytes.length - 1);
            for (uint256 i = 0; i < trimmed.length; i++) {
                trimmed[i] = outDirBytes[i];
            }
            normalizedOutDir = string(trimmed);
        }

        // Detect Hardhat specifically by checking for artifacts/contracts prefix
        // Hardhat sets FOUNDRY_OUT=artifacts/contracts, and build-info is at artifacts/build-info
        if (
            StringFinder.startsWith(normalizedOutDir, "artifacts/contracts") ||
            StringFinder.startsWith(normalizedOutDir, "artifacts\\contracts")
        ) {
            return "artifacts/build-info";
        }

        // Default: Foundry uses outDir/build-info (works for custom FOUNDRY_OUT values)
        return string(abi.encodePacked(normalizedOutDir, "/build-info"));
    }

    /**
     * Gets the path to the build-info file that contains the given bytecode.
     *
     * @param sourceCodeHash keccak256 hash of the source code from metadata
     * @param contractName Contract name to display in error message if build-info file is not found
     * @param outDir Foundry output directory that contains a build-info directory
     * @return The path to the build-info file that contains the given bytecode
     */
    function getBuildInfoFile(
        string memory sourceCodeHash,
        string memory contractName,
        string memory outDir
    ) internal returns (string memory) {
        string memory buildInfoDir = getBuildInfoDir(outDir);
        string[] memory inputs = new string[](4);
        inputs[0] = "grep";
        inputs[1] = "-rl";
        inputs[2] = string(abi.encodePacked('"', sourceCodeHash, '"'));
        inputs[3] = buildInfoDir;

        Vm.FfiResult memory result = runAsBashCommand(inputs);
        string memory stdout = string(result.stdout);

        if (!stdout.endsWith(".json")) {
            revert(
                string(
                    abi.encodePacked(
                        "Could not find build-info file with matching source code hash for contract ",
                        contractName
                    )
                )
            );
        }

        return stdout;
    }

    /**
     * @dev Gets the output directory from the FOUNDRY_OUT environment variable, or defaults to "out" if not set.
     */
    function getOutDir() internal view returns (string memory) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        string memory defaultOutDir = "out";
        return vm.envOr("FOUNDRY_OUT", defaultOutDir);
    }

    function _toFileName(string memory name) private pure returns (string memory) {
        Vm vm = Vm(CHEATCODE_ADDRESS);
        if (name.endsWith(".sol")) {
            return name;
        } else if (name.count(":") == 1) {
            return vm.split(name, ":")[0];
        } else {
            if (name.endsWith(".json")) {
                string[] memory parts = vm.split(name, "/");
                if (parts.length > 1) {
                    return parts[parts.length - 2];
                }
            }

            revert(
                string(
                    abi.encodePacked(
                        "Contract name ",
                        name,
                        " must be in the format MyContract.sol:MyContract or MyContract.sol or out/MyContract.sol/MyContract.json"
                    )
                )
            );
        }
    }

    function _toShortName(string memory name) private pure returns (string memory) {
        Vm vm = Vm(CHEATCODE_ADDRESS);
        if (name.endsWith(".sol") && name.count(".sol") == 1) {
            return vm.replace(name, ".sol", "");
        } else if (name.count(":") == 1) {
            return vm.split(name, ":")[1];
        } else if (name.endsWith(".json") && name.count(".json") == 1) {
            string[] memory parts = vm.split(name, "/");
            string memory jsonName = parts[parts.length - 1];
            return vm.replace(jsonName, ".json", "");
        } else {
            revert(
                string(
                    abi.encodePacked(
                        "Contract name ",
                        name,
                        " must be in the format MyContract.sol:MyContract or MyContract.sol or out/MyContract.sol/MyContract.json"
                    )
                )
            );
        }
    }

    /**
     * @dev Converts an array of inputs to a bash command.
     * @param inputs Inputs for a command, e.g. ["grep", "-rl", "0x1234", "out/build-info"]
     * @param bashPath Path to the bash executable or just "bash" if it is in the PATH
     * @return A bash command that runs the given inputs, e.g. ["bash", "-c", "grep -rl 0x1234 out/build-info"]
     */
    function toBashCommand(string[] memory inputs, string memory bashPath) internal pure returns (string[] memory) {
        string memory commandString;
        for (uint i = 0; i < inputs.length; i++) {
            commandString = string(abi.encodePacked(commandString, inputs[i]));
            if (i != inputs.length - 1) {
                commandString = string(abi.encodePacked(commandString, " "));
            }
        }

        string[] memory result = new string[](3);
        result[0] = bashPath;
        result[1] = "-c";
        result[2] = commandString;
        return result;
    }

    /**
     * @dev Runs an arbitrary command using bash.
     * @param inputs Inputs for a command, e.g. ["grep", "-rl", "0x1234", "out/build-info"]
     * @return The result of the corresponding bash command as a Vm.FfiResult struct
     */
    function runAsBashCommand(string[] memory inputs) internal returns (Vm.FfiResult memory) {
        Vm vm = Vm(CHEATCODE_ADDRESS);
        string memory defaultBashPath = "bash";
        string memory bashPath = vm.envOr("OPENZEPPELIN_BASH_PATH", defaultBashPath);

        string[] memory bashCommand = toBashCommand(inputs, bashPath);
        Vm.FfiResult memory result = vm.tryFfi(bashCommand);
        if (result.exitCode != 0 && result.stdout.length == 0 && result.stderr.length == 0) {
            // On Windows, using the bash executable from WSL leads to a non-zero exit code and no output
            revert(
                string(
                    abi.encodePacked(
                        'Failed to run bash command with "',
                        bashCommand[0],
                        '". If you are using Windows, set the OPENZEPPELIN_BASH_PATH environment variable to the fully qualified path of the bash executable, using forward slashes (for example, with Git for Windows: OPENZEPPELIN_BASH_PATH="C:/Program Files/Git/bin/bash"). In a Foundry project, you can set this in your .env file.'
                    )
                )
            );
        } else {
            return result;
        }
    }
}
