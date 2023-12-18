// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {strings} from "solidity-stringutils/strings.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Utils} from "./internal/Utils.sol";

/**
 * @dev Library for deploying and managing upgradeable contracts from Forge scripts or tests.
 */
library Defender {
    address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    using strings for *;

    function deployContract(string memory contractName) internal returns (string memory) {
        return _deploy(contractName);
    }

    function _deploy(string memory contractName) private returns (string memory) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        string memory outDir = Utils.getOutDir();
        (string memory contractPath, string memory shortName, string memory bytecode) = Utils.getContractIdentifiers(
            contractName,
            outDir
        );
        string memory buildInfoFile = Utils.getBuildInfoFile(bytecode, shortName, outDir);

        string[] memory inputs = _buildDeployCommand(shortName, contractPath, buildInfoFile);

        string memory result = string(vm.ffi(inputs));
        console.log(result);

        strings.slice memory delim = "Deployed to address: ".toSlice();
        if (result.toSlice().contains(delim)) {
            return result.toSlice().copy().find(delim).beyond(delim).toString();
        } else {
            // TODO extract stderr by using vm.tryFfi
            revert(string.concat("Failed to deploy contract ", contractName, ". See error messages above."));
        }
    }

    function _buildDeployCommand(string memory shortName, string memory contractPath, string memory buildInfoFile) private view returns (string[] memory) {
        string[] memory inputBuilder = new string[](255);

        uint8 i = 0;

        inputBuilder[i++] = "npx";
        inputBuilder[i++] = "defender-cli";
        inputBuilder[i++] = "deploy";
        inputBuilder[i++] = "--contractName";
        inputBuilder[i++] = shortName;
        inputBuilder[i++] = "--contractPath";
        inputBuilder[i++] = contractPath;
        inputBuilder[i++] = "--network";
        inputBuilder[i++] = Strings.toString(block.chainid);
        inputBuilder[i++] = "--artifactPayload";
        inputBuilder[i++] = buildInfoFile;

        // Create a copy of inputs but with the correct length
        string[] memory inputs = new string[](i);
        for (uint8 j = 0; j < i; j++) {
            inputs[j] = inputBuilder[j];
        }

        return inputs;
    }

}