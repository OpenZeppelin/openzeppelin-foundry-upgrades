// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {strings} from "solidity-stringutils/src/strings.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Utils, ContractInfo} from "./Utils.sol";
import {Versions} from "./Versions.sol";
import {Options} from "../Upgrades.sol";

/**
 * @dev Internal helper methods for Defender deployments.
 *
 * DO NOT USE DIRECTLY. Use Defender.sol instead.
 */
library DefenderDeploy {
    using strings for *;

    function deploy(
        string memory contractName,
        bytes memory constructorData,
        Options memory opts
    ) internal returns (address) {
        string memory outDir = Utils.getOutDir();
        ContractInfo memory contractInfo = Utils.getContractInfo(contractName, outDir);
        string memory buildInfoFile = Utils.getBuildInfoFile(
            contractInfo.sourceCodeHash,
            contractInfo.shortName,
            outDir
        );

        string[] memory inputs = buildDeployCommand(contractInfo, buildInfoFile, constructorData, opts);

        Vm.FfiResult memory result = Utils.runAsBashCommand(inputs);
        string memory stdout = string(result.stdout);

        if (result.exitCode != 0) {
            revert(string.concat("Failed to deploy contract ", contractName, ": ", string(result.stderr)));
        }

        strings.slice memory delim = "Deployed to address: ".toSlice();
        if (stdout.toSlice().contains(delim)) {
            string memory deployedAddress = stdout.toSlice().copy().find(delim).beyond(delim).toString();
            return Vm(Utils.CHEATCODE_ADDRESS).parseAddress(deployedAddress);
        } else {
            revert(string.concat("Failed to parse deployment address from output: ", stdout));
        }
    }

    function buildDeployCommand(
        ContractInfo memory contractInfo,
        string memory buildInfoFile,
        bytes memory constructorData,
        Options memory opts
    ) internal view returns (string[] memory) {
        Vm vm = Vm(Utils.CHEATCODE_ADDRESS);

        string[] memory inputBuilder = new string[](255);

        uint8 i = 0;

        inputBuilder[i++] = "npx";
        inputBuilder[i++] = string.concat(
            "@openzeppelin/defender-deploy-client-cli@",
            Versions.DEFENDER_DEPLOY_CLIENT_CLI
        );
        inputBuilder[i++] = "deploy";
        inputBuilder[i++] = "--contractName";
        inputBuilder[i++] = contractInfo.shortName;
        inputBuilder[i++] = "--contractPath";
        inputBuilder[i++] = contractInfo.contractPath;
        inputBuilder[i++] = "--chainId";
        inputBuilder[i++] = Strings.toString(block.chainid);
        inputBuilder[i++] = "--artifactFile";
        inputBuilder[i++] = buildInfoFile;
        inputBuilder[i++] = "--licenseType";
        inputBuilder[i++] = contractInfo.license;
        if (constructorData.length > 0) {
            inputBuilder[i++] = "--constructorBytecode";
            inputBuilder[i++] = vm.toString(constructorData);
        }
        if (opts.skipVerifySourceCode) {
            inputBuilder[i++] = "--verifySourceCode";
            inputBuilder[i++] = "false";
        }
        if (!(opts.relayerId).toSlice().empty()) {
            inputBuilder[i++] = "--relayerId";
            inputBuilder[i++] = opts.relayerId;
        }
        if (opts.salt != 0) {
            inputBuilder[i++] = "--salt";
            inputBuilder[i++] = vm.toString(opts.salt);
        }

        // Create a copy of inputs but with the correct length
        string[] memory inputs = new string[](i);
        for (uint8 j = 0; j < i; j++) {
            inputs[j] = inputBuilder[j];
        }

        return inputs;
    }
}
