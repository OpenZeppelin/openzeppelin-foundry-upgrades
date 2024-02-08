// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {strings} from "solidity-stringutils/src/strings.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Utils, ContractInfo} from "./Utils.sol";
import {Versions} from "./Versions.sol";
import {Options, DefenderOptions} from "../Options.sol";
import {ProposeUpgradeResponse} from "../Defender.sol";

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
        DefenderOptions memory defenderOpts
    ) internal returns (address) {
        string memory outDir = Utils.getOutDir();
        ContractInfo memory contractInfo = Utils.getContractInfo(contractName, outDir);
        string memory buildInfoFile = Utils.getBuildInfoFile(
            contractInfo.sourceCodeHash,
            contractInfo.shortName,
            outDir
        );

        string[] memory inputs = buildDeployCommand(contractInfo, buildInfoFile, constructorData, defenderOpts);

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
        DefenderOptions memory defenderOpts
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
        if (defenderOpts.skipVerifySourceCode) {
            inputBuilder[i++] = "--verifySourceCode";
            inputBuilder[i++] = "false";
        }
        if (!(defenderOpts.relayerId).toSlice().empty()) {
            inputBuilder[i++] = "--relayerId";
            inputBuilder[i++] = defenderOpts.relayerId;
        }
        if (defenderOpts.salt != 0) {
            inputBuilder[i++] = "--salt";
            inputBuilder[i++] = vm.toString(defenderOpts.salt);
        }

        // Create a copy of inputs but with the correct length
        string[] memory inputs = new string[](i);
        for (uint8 j = 0; j < i; j++) {
            inputs[j] = inputBuilder[j];
        }

        return inputs;
    }

    function proposeUpgrade(
        address proxyAddress,
        address proxyAdminAddress,
        address newImplementationAddress,
        string memory newImplementationContractName,
        Options memory opts
    ) internal returns (ProposeUpgradeResponse memory) {
        Vm vm = Vm(Utils.CHEATCODE_ADDRESS);

        string memory outDir = Utils.getOutDir();
        ContractInfo memory contractInfo = Utils.getContractInfo(newImplementationContractName, outDir);

        string[] memory inputs = buildProposeUpgradeCommand(
            proxyAddress,
            proxyAdminAddress,
            newImplementationAddress,
            contractInfo,
            opts
        );

        Vm.FfiResult memory result = Utils.runAsBashCommand(inputs);
        string memory stdout = string(result.stdout);

        if (result.exitCode != 0) {
            revert(
                string.concat(
                    "Failed to propose upgrade for proxy ",
                    vm.toString(proxyAddress),
                    ": ",
                    string(result.stderr)
                )
            );
        }

        return parseProposeUpgradeResponse(stdout);
    }

    function parseProposeUpgradeResponse(string memory stdout) internal pure returns (ProposeUpgradeResponse memory) {
        ProposeUpgradeResponse memory response;

        strings.slice memory idDelim = "Proposal ID: ".toSlice();
        strings.slice memory urlDelim = "Proposal URL: ".toSlice();

        if (stdout.toSlice().contains(idDelim)) {
            strings.slice memory idSlice = stdout.toSlice().copy().find(idDelim).beyond(idDelim);
            // Remove any following lines, such as the Proposal URL line
            if (idSlice.contains("\n".toSlice())) {
                idSlice = idSlice.split("\n".toSlice());
            }
            response.proposalId = idSlice.toString();
        } else {
            revert(string.concat("Failed to parse proposal ID from output: ", stdout));
        }

        if (stdout.toSlice().contains(urlDelim)) {
            response.url = stdout.toSlice().copy().find(urlDelim).beyond(urlDelim).toString();
        }

        return response;
    }

    function buildProposeUpgradeCommand(
        address proxyAddress,
        address proxyAdminAddress,
        address newImplementationAddress,
        ContractInfo memory contractInfo,
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
        inputBuilder[i++] = "proposeUpgrade";
        inputBuilder[i++] = "--proxyAddress";
        inputBuilder[i++] = vm.toString(proxyAddress);
        inputBuilder[i++] = "--newImplementationAddress";
        inputBuilder[i++] = vm.toString(newImplementationAddress);
        inputBuilder[i++] = "--chainId";
        inputBuilder[i++] = Strings.toString(block.chainid);
        inputBuilder[i++] = "--abiFile";
        inputBuilder[i++] = contractInfo.artifactPath;
        if (proxyAdminAddress != address(0)) {
            inputBuilder[i++] = "--proxyAdminAddress";
            inputBuilder[i++] = vm.toString(proxyAdminAddress);
        }
        if (!(opts.defender.upgradeApprovalProcessId).toSlice().empty()) {
            inputBuilder[i++] = "--approvalProcessId";
            inputBuilder[i++] = opts.defender.upgradeApprovalProcessId;
        }

        // Create a copy of inputs but with the correct length
        string[] memory inputs = new string[](i);
        for (uint8 j = 0; j < i; j++) {
            inputs[j] = inputBuilder[j];
        }

        return inputs;
    }
}
