// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DefenderOptions} from "./Options.sol";
import {DefenderDeploy} from "./internal/DefenderDeploy.sol";

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
     * @return Address of the deployed contract
     */
    function deployContract(string memory contractName) internal returns (address) {
        return deployContract(contractName, "");
    }

    /**
     * @dev Deploys a contract to the current network using OpenZeppelin Defender.
     *
     * WARNING: Do not use this function directly if you are deploying an upgradeable contract. This function does not validate whether the contract is upgrade safe.
     *
     * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param opts Defender deployment options. Note that the `useDefenderDeploy` option is always treated as `true` when called from this function.
     * @return Address of the deployed contract
     */
    function deployContract(string memory contractName, DefenderOptions memory opts) internal returns (address) {
        return deployContract(contractName, "", opts);
    }

    /**
     * @dev Deploys a contract with constructor arguments to the current network using OpenZeppelin Defender.
     *
     * WARNING: Do not use this function directly if you are deploying an upgradeable contract. This function does not validate whether the contract is upgrade safe.
     *
     * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param constructorData Encoded constructor arguments
     * @return Address of the deployed contract
     */
    function deployContract(string memory contractName, bytes memory constructorData) internal returns (address) {
        DefenderOptions memory opts;
        return deployContract(contractName, constructorData, opts);
    }

    /**
     * @dev Deploys a contract with constructor arguments to the current network using OpenZeppelin Defender.
     *
     * WARNING: Do not use this function directly if you are deploying an upgradeable contract. This function does not validate whether the contract is upgrade safe.
     *
     * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param constructorData Encoded constructor arguments
     * @param opts Defender deployment options. Note that the `useDefenderDeploy` option is always treated as `true` when called from this function.
     * @return Address of the deployed contract
     */
    function deployContract(
        string memory contractName,
        bytes memory constructorData,
        DefenderOptions memory opts
    ) internal returns (address) {
        return DefenderDeploy.deploy(contractName, constructorData, opts);
    }
}
