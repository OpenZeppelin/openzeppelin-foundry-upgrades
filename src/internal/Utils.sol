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

    function getFullyQualifiedName(
        string memory outDir,
        string memory contractName
    ) internal view returns (string memory) {
        (string memory shortName, string memory contractPath) = getContractNameComponents(outDir, contractName);
        return string.concat(contractPath, ":", shortName);
    }

    function getContractNameComponents(
        string memory outDir,
        string memory contractName
    ) internal view returns (string memory, string memory) {
        Vm vm = Vm(CHEATCODE_ADDRESS);

        string memory shortName = _toShortName(contractName);
        string memory contractFileName = _toContractFileName(contractName);

        string memory artifactPath = string.concat(vm.projectRoot(), "/", outDir, "/", contractFileName, "/", shortName, ".json");
        string memory artifactJson = vm.readFile(artifactPath);

        string memory contractPath = string(vm.parseJson(artifactJson, ".ast.absolutePath"));
        
        return (shortName, contractPath);
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
