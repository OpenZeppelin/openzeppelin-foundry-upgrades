// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Common options.
 */
struct Options {
    /*
     * The reference contract to use for storage layout comparisons, e.g. "ContractV1.sol" or "ContractV1.sol:ContractV1" or
     * artifact path relative to the project root directory.
     *
     * If not set, attempts to use the `@custom:oz-upgrades-from <reference>` annotation from the contract.
     *
     * NOTE: This option is not compatible with the `referenceBuildInfoDir` option. If using the `referenceBuildInfoDir` option,
     * set the `@custom:oz-upgrades-from <reference>` annotation.
     */
    string referenceContract;
    /*
     * Path of a reference build info directory from a previous version of the project to use for storage layout comparisons.
     *
     * When using this option, refer to this directory using prefix `<dirName>:` before the contract name or fully qualified name
     * in the `@custom:oz-upgrades-from` annotation, where `<dirName>` is the directory short name.
     * The directory short name must be unique when compared to the main build info directory.
     *
     * For example, if the reference build info directory is `previous-builds/build-info-v1`, and the reference contract is `ContractV1`,
     * then the annotation should be `/// @custom:oz-upgrades-from old-builds/build-info-v1:ContractV1`
     */
    string referenceBuildInfoDir;
    /*
     * Encoded constructor arguments for the implementation contract.
     * Note that these are different from initializer arguments, and will be used in the deployment of the implementation contract itself.
     * Can be used to initialize immutable variables.
     */
    bytes constructorData;
    /*
     * Exclude validations for contracts in source file paths that match any of the given glob patterns.
     * For example, ["contracts/helpers/*.sol"]. Does not apply to reference contracts.
     */
    string[] exclude;
    /*
     * Selectively disable one or more validation errors. Comma-separated list that must be compatible with the
     * --unsafeAllow option described in https://docs.openzeppelin.com/upgrades-plugins/1.x/api-core#usage
     */
    string unsafeAllow;
    /*
     * Configure storage layout check to allow variable renaming
     */
    bool unsafeAllowRenames;
    /*
     * Skips checking for storage layout compatibility errors. This is a dangerous option meant to be used as a last resort.
     */
    bool unsafeSkipStorageCheck;
    /*
     * Skips all upgrade safety checks. This is a dangerous option meant to be used as a last resort.
     */
    bool unsafeSkipAllChecks;
    /*
     * Options for OpenZeppelin Defender deployments.
     */
    DefenderOptions defender;
}

/**
 * Options for OpenZeppelin Defender deployments.
 */
struct DefenderOptions {
    /*
     * Deploys contracts using OpenZeppelin Defender instead of broadcasting deployments through Forge. Defaults to `false`. See DEFENDER.md.
     *
     * NOTE: If using an EOA or Safe to deploy, go to https://defender.openzeppelin.com/v2/#/deploy[Defender deploy] to submit the pending deployment(s) while the script is running.
     * The script waits for each deployment to complete before it continues.
     */
    bool useDefenderDeploy;
    /*
     * When using OpenZeppelin Defender deployments, whether to skip verifying source code on block explorers. Defaults to `false`.
     */
    bool skipVerifySourceCode;
    /*
     * When using OpenZeppelin Defender deployments, the ID of the relayer to use for the deployment. Defaults to the relayer configured for your deployment environment on Defender.
     */
    string relayerId;
    /*
     * Applies to OpenZeppelin Defender deployments only.
     * If this is not set, deployments will be performed using the CREATE opcode.
     * If this is set, deployments will be performed using the CREATE2 opcode with the provided salt.
     * Note that deployments using a Safe are done using CREATE2 and require a salt.
     *
     * WARNING: CREATE2 affects `msg.sender` behavior. See https://docs.openzeppelin.com/defender/v2/tutorial/deploy#deploy-caveat for more information.
     */
    bytes32 salt;
    /*
     * The ID of the upgrade approval process to use when proposing an upgrade.
     * Defaults to the upgrade approval process configured for your deployment environment on Defender.
     */
    string upgradeApprovalProcessId;
    /*
     * License type to display on block explorers for verified source code.
     * See https://etherscan.io/contract-license-types for supported values and use the string found in brackets, e.g. MIT.
     * If not set, infers the license type by using the SPDX license identifier from the contract's Solidity file.
     * Cannot be set if `skipLicenseType` or `skipVerifySourceCode` is `true`.
     */
    string licenseType;
    /*
     * If set to `true`, does not set the license type on block explorers for verified source code.
     * Use this if your contract's license type is not supported by block explorers.
     * Defaults to `false`.
     */
    bool skipLicenseType;
    /*
     * Transaction overrides for OpenZeppelin Defender deployments.
     */
    TxOverrides txOverrides;
}

/**
 * Transaction overrides for OpenZeppelin Defender deployments.
 */
struct TxOverrides {
    /*
     * Maximum amount of gas to allow the deployment transaction to use.
     */
    uint256 gasLimit;
    /*
     * Gas price for legacy transactions, in wei.
     */
    uint256 gasPrice;
    /*
     * Maximum total fee per gas, in wei.
     */
    uint256 maxFeePerGas;
    /*
     * Maximum priority fee per gas, in wei.
     */
    uint256 maxPriorityFeePerGas;
}
