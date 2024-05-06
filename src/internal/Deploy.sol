// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from "forge-std/Vm.sol";
import {Utils} from "./Utils.sol";

/**
 * @dev Internal helper methods for deployments.
 *
 * WARNING: DO NOT USE DIRECTLY. Use Upgrades.sol instead.
 */
library Deploy {
    function deploy(string memory contractName, bytes memory constructorData) internal returns (address) {
        bytes memory creationCode = Vm(Utils.CHEATCODE_ADDRESS).getCode(contractName);
        address deployedAddress = _deployFromBytecode(abi.encodePacked(creationCode, constructorData));
        if (deployedAddress == address(0)) {
            revert(
                string(
                    abi.encodePacked(
                        "Failed to deploy contract ",
                        contractName,
                        ' using constructor data "',
                        string(constructorData),
                        '"'
                    )
                )
            );
        }
        return deployedAddress;
    }

    function _deployFromBytecode(bytes memory bytecode) private returns (address) {
        address addr;
        assembly {
            addr := create(0, add(bytecode, 32), mload(bytecode))
        }
        return addr;
    }
}
