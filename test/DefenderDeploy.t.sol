// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Utils, ContractInfo} from "openzeppelin-foundry-upgrades/internal/Utils.sol";
import {DefenderDeploy} from "openzeppelin-foundry-upgrades/internal/DefenderDeploy.sol";
import {Versions} from "openzeppelin-foundry-upgrades/internal/Versions.sol";

contract DefenderDeployTest is Test {
    function testBuildDeployCommand() public {
        ContractInfo memory contractInfo = Utils.getContractInfo("MyContractFile.sol:MyContractName", "out");
        string memory buildInfoFile = Utils.getBuildInfoFile(contractInfo.bytecode, contractInfo.shortName, "out");

        string[] memory command = DefenderDeploy.buildDeployCommand(contractInfo, buildInfoFile);

        // convert to string for easier comparison
        string memory commandString;
        for (uint i = 0; i < command.length; i++) {
            commandString = string.concat(commandString, command[i]);
            if (i < command.length - 1) {
                commandString = string.concat(commandString, " ");
            }
        }

        assertEq(
            commandString,
            string.concat(
                "npx @openzeppelin/defender-deploy-client-cli@",
                Versions.DEFENDER_DEPLOY_CLIENT_CLI,
                " deploy --contractName MyContractName --contractPath test/contracts/MyContractFile.sol --chainId 31337 --artifactFile ",
                buildInfoFile,
                " --licenseType MIT"
            )
        );
    }
}
