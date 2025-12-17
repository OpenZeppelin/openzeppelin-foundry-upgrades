// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Utils, ContractInfo} from "openzeppelin-foundry-upgrades/internal/Utils.sol";
import {StringFinder} from "openzeppelin-foundry-upgrades/internal/StringFinder.sol";

import {Greeter} from "./contracts/Greeter.sol";

/**
 * @dev Tests to ensure compatibility with Hardhat 3 environment.
 *
 * Hardhat 3 uses:
 * - artifacts/contracts/ as the output directory (instead of out/)
 * - artifacts/build-info/ for build info files
 * - FOUNDRY_OUT environment variable should point to artifacts/contracts
 *
 * This test ensures that the foundry-upgrades library works correctly
 * when FOUNDRY_OUT is set to match Hardhat's structure.
 *
 * NOTE: This test MUST be run via scripts/test-hh3-compatibility.sh
 * which sets up the HH3 artifacts and build-info files in the correct location.
 *
 * HH3 Fixture Generation:
 * Generated from the openzeppelin-upgrades repo (https://github.com/OpenZeppelin/openzeppelin-upgrades).
 * Compile in packages/plugin-hardhat with `npx hardhat compile`. The plugin-hardhat hook injects AST
 * into artifacts during compilation, which is required for upgrade safety checks.
 *
 * After compilation, copy files from packages/plugin-hardhat to this repo's fixtures directory:
 * - Artifacts: from artifacts/contracts/<source-path>/<Contract>.json to test/fixtures/hh3-artifacts/contracts/...
 * - Build-info: from artifacts/build-info/*.json to test/fixtures/hh3-artifacts/build-info/
 */
contract HH3CompatibilityTest is Test {
    using StringFinder for string;

    string constant HH3_OUT_DIR = "artifacts/contracts";
    string constant DEFAULT_OUT_DIR = "out";

    /**
     * @dev Test that Utils.getOutDir() respects FOUNDRY_OUT environment variable.
     *
     * NOTE: FOUNDRY_OUT must be set externally via the test script.
     * vm.setEnv() does not work for FOUNDRY_* variables as Foundry treats them specially.
     */
    function testGetOutDir_respectsFOUNDRY_OUT() public {
        string memory outDir = Utils.getOutDir();
        assertEq(outDir, HH3_OUT_DIR, "Utils.getOutDir() should respect FOUNDRY_OUT");
    }

    /**
     * @dev Test that vm.envOr() fallback works correctly when variable doesn't exist.
     *
     * This validates the fallback mechanism used by Utils.getOutDir().
     */
    function testGetOutDir_fallbackToDefault() public {
        string memory defaultValue = "out";
        string memory defaultOut = vm.envOr("FOUNDRY_OUT_NONEXISTENT", defaultValue);
        assertEq(defaultOut, "out");
    }

    /**
     * @dev Test that getContractInfo works with HH3 artifact structure.
     *
     * The HH3 artifact was copied from fixtures by the script and placed
     * in artifacts/contracts/test/contracts/Greeter.sol/Greeter.json
     */
    function testGetContractInfo_withHH3Structure() public {
        ContractInfo memory info = Utils.getContractInfo("Greeter.sol", HH3_OUT_DIR);

        assertEq(info.shortName, "Greeter", "Contract name should be Greeter");
        assertEq(info.contractPath, "test/contracts/Greeter.sol", "Contract path should match");
        assertTrue(bytes(info.contractPath).length > 0, "Contract path should not be empty");
    }

    /**
     * @dev Test that getContractInfo works with Foundry's default structure.
     *
     * This validates backward compatibility - the library should still work
     * with the standard Foundry output directory structure.
     *
     * NOTE: This test passes the outDir directly, not via Utils.getOutDir(),
     * because FOUNDRY_OUT is set to artifacts/contracts by the script.
     */
    function testGetContractInfo_withFoundryStructure() public {
        ContractInfo memory info = Utils.getContractInfo("Greeter.sol", DEFAULT_OUT_DIR);

        assertEq(info.shortName, "Greeter", "Contract name should be Greeter");
        assertEq(info.contractPath, "test/contracts/Greeter.sol", "Contract path should match");
    }

    /**
     * @dev Test that FOUNDRY_OUT environment variable can be read via vm.envOr.
     *
     * NOTE: FOUNDRY_OUT must be set externally via the test script.
     * vm.setEnv() does not work for FOUNDRY_* variables.
     */
    function testFOUNDRY_OUT_environmentVariable() public {
        string memory defaultValue = "out";
        string memory foundryOut = vm.envOr("FOUNDRY_OUT", defaultValue);
        assertEq(foundryOut, HH3_OUT_DIR, "FOUNDRY_OUT should be set by the test script");
    }

    /**
     * @dev Test that getBuildInfoFile works with HH3 structure.
     *
     * This verifies that build-info files can be found in artifacts/build-info/
     * (not out/build-info/) when using HH3 structure.
     *
     * The HH3 build-info files were copied from fixtures by the script and placed
     * in artifacts/build-info/
     */
    function testGetBuildInfoFile_withHH3Structure() public {
        ContractInfo memory contractInfo = Utils.getContractInfo("Greeter.sol", HH3_OUT_DIR);
        string memory buildInfoFile = Utils.getBuildInfoFile(
            contractInfo.sourceCodeHash,
            contractInfo.shortName,
            HH3_OUT_DIR
        );

        assertTrue(buildInfoFile.startsWith("artifacts/build-info"), "Build-info path should start with artifacts/build-info for HH3");
        assertTrue(buildInfoFile.endsWith(".json"), "Build-info path should end with .json");
    }
}
