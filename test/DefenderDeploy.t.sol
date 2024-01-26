// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Utils, ContractInfo} from "openzeppelin-foundry-upgrades/internal/Utils.sol";
import {DefenderDeploy} from "openzeppelin-foundry-upgrades/internal/DefenderDeploy.sol";
import {Versions} from "openzeppelin-foundry-upgrades/internal/Versions.sol";
import {WithConstructor} from "./contracts/WithConstructor.sol";

contract DefenderDeployTest is Test {
    function _toString(string[] memory arr) private pure returns (string memory) {
        string memory result;
        for (uint i = 0; i < arr.length; i++) {
            result = string.concat(result, arr[i]);
            if (i < arr.length - 1) {
                result = string.concat(result, " ");
            }
        }
        return result;
    }

    function testBuildDeployCommand() public {
        ContractInfo memory contractInfo = Utils.getContractInfo("MyContractFile.sol:MyContractName", "out");
        string memory buildInfoFile = Utils.getBuildInfoFile(contractInfo.sourceCodeHash, contractInfo.shortName, "out");

        string memory commandString = _toString(DefenderDeploy.buildDeployCommand(contractInfo, buildInfoFile, ""));

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

    function testBuildDeployCommandWithConstructorData() public {
        ContractInfo memory contractInfo = Utils.getContractInfo("WithConstructor.sol:WithConstructor", "out");
        string memory buildInfoFile = Utils.getBuildInfoFile(contractInfo.sourceCodeHash, contractInfo.shortName, "out");

        bytes memory constructorData = abi.encode(123);

        string memory commandString = _toString(
            DefenderDeploy.buildDeployCommand(contractInfo, buildInfoFile, constructorData)
        );

        assertEq(
            commandString,
            string.concat(
                "npx @openzeppelin/defender-deploy-client-cli@",
                Versions.DEFENDER_DEPLOY_CLIENT_CLI,
                " deploy --contractName WithConstructor --contractPath test/contracts/WithConstructor.sol --chainId 31337 --artifactFile ",
                buildInfoFile,
                " --licenseType MIT --constructorBytecode 0x000000000000000000000000000000000000000000000000000000000000007b"
            )
        );
    }
}
