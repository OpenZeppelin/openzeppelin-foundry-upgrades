// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {strings} from "solidity-stringutils/strings.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Utils, ContractInfo} from "./Utils.sol";
import {Versions} from "./Versions.sol";

/**
 * @dev Internal helper methods for Defender deployments.
 *
 * DO NOT USE DIRECTLY. Use Defender.sol instead.
 */
library DefenderDeploy {
    using strings for *;

    function deploy(string memory contractName) internal returns (string memory) {
        Vm vm = Vm(Utils.CHEATCODE_ADDRESS);

        string memory outDir = Utils.getOutDir();
        ContractInfo memory contractInfo = Utils.getContractInfo(contractName, outDir);
        string memory buildInfoFile = Utils.getBuildInfoFile(contractInfo.bytecode, contractInfo.shortName, outDir);

        string[] memory inputs = buildDeployCommand(contractInfo, buildInfoFile);

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

    function buildDeployCommand(
        ContractInfo memory contractInfo,
        string memory buildInfoFile
    ) internal view returns (string[] memory) {
        string[] memory inputs = new string[](13);

        uint8 i = 0;

        inputs[i++] = "npx";
        inputs[i++] = string.concat("@openzeppelin/defender-deploy-client-cli@", Versions.DEFENDER_DEPLOY_CLIENT_CLI);
        inputs[i++] = "deploy";
        inputs[i++] = "--contractName";
        inputs[i++] = contractInfo.shortName;
        inputs[i++] = "--contractPath";
        inputs[i++] = contractInfo.contractPath;
        inputs[i++] = "--chainId";
        inputs[i++] = Strings.toString(block.chainid);
        inputs[i++] = "--artifactFile";
        inputs[i++] = buildInfoFile;
        inputs[i++] = "--licenseType";
        inputs[i++] = contractInfo.license;

        return inputs;
    }
}
