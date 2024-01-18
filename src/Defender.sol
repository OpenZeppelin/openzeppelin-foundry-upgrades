// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DefenderDeploy} from "./internal/DefenderDeploy.sol";
import {Options} from "./Upgrades.sol";

/**
 * @dev Library for interacting with OpenZeppelin Defender from Forge scripts or tests.
 */
library Defender {
    /**
     * @dev Deploys a contract to the current network using OpenZeppelin Defender.
     *
     * WARNING: Do not use this function directly if you are deploying an upgradeable contract. This function does not validate whether the contract is upgrade safe.
     *
     * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     */
    function deployContract(string memory contractName) internal returns (string memory) {
        Options memory opts;
        return deployContract(contractName, opts);
    }

    /**
     * @dev Deploys a contract to the current network using OpenZeppelin Defender.
     *
     * WARNING: Do not use this function directly if you are deploying an upgradeable contract. This function does not validate whether the contract is upgrade safe.
     *
     * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param opts Options for the deployment
     */
    function deployContract(string memory contractName, Options memory opts) internal returns (string memory) {
        return DefenderDeploy.deploy(contractName, opts);
    }
}
