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
        // Verify artifact path is from HH3 structure, not Foundry's default "out" dir
        assertTrue(vm.contains(info.artifactPath, HH3_OUT_DIR), "Artifact path should contain HH3 output dir");
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

        assertTrue(
            buildInfoFile.startsWith("artifacts/build-info"),
            "Build-info path should start with artifacts/build-info for HH3"
        );
        assertTrue(buildInfoFile.endsWith(".json"), "Build-info path should end with .json");

        // Verify this is actually an HH3 build-info file by checking its format
        string memory buildInfoJson = vm.readFile(buildInfoFile);
        assertTrue(vm.keyExistsJson(buildInfoJson, "._format"), "Build-info should have _format field");
        string memory format = vm.parseJsonString(buildInfoJson, "._format");
        assertEq(format, "hh3-sol-build-info-output-1", "Build-info should be HH3 format");
    }

    /**
     * @dev Exercises the by-name fallback in getContractInfo. When the direct lookup
     * misses, the fallback must still resolve the artifact and return an absolute path,
     * so callers get a consistent result regardless of how it was found.
     */
    function testGetContractInfo_byNameFallback() public {
        string[] memory mkdirArgs = new string[](3);
        mkdirArgs[0] = "mkdir";
        mkdirArgs[1] = "-p";
        mkdirArgs[2] = "artifacts/contracts/recursive-probe/Stub.sol";
        vm.ffi(mkdirArgs);

        string[] memory cpArgs = new string[](3);
        cpArgs[0] = "cp";
        cpArgs[1] = "test/fixtures/hh3-artifacts/contracts/test/contracts/Greeter.sol/Greeter.json";
        cpArgs[2] = "artifacts/contracts/recursive-probe/Stub.sol/Stub.json";
        vm.ffi(cpArgs);

        ContractInfo memory info = Utils.getContractInfo("Stub.sol", HH3_OUT_DIR);

        assertEq(info.shortName, "Stub");
        assertTrue(info.artifactPath.startsWith(vm.projectRoot()), "artifactPath should be absolute");
        assertTrue(
            vm.contains(info.artifactPath, "recursive-probe/Stub.sol/Stub.json"),
            "artifactPath should point to the nested fixture"
        );
    }

    /**
     * @dev By-name fallback must still resolve the artifact when the search directory
     * contains spaces. Guards against regressing to an unquoted path being passed to the
     * underlying shell command, where bash would split the single argument on whitespace.
     */
    function testGetContractInfo_byNameFallback_outDirWithSpaces() public {
        string memory spacesOutDir = "artifacts/dir with spaces";
        string memory nestedDir = string.concat(spacesOutDir, "/nested/Stub.sol");

        string[] memory mkdirArgs = new string[](3);
        mkdirArgs[0] = "mkdir";
        mkdirArgs[1] = "-p";
        mkdirArgs[2] = nestedDir;
        vm.ffi(mkdirArgs);

        string[] memory cpArgs = new string[](3);
        cpArgs[0] = "cp";
        cpArgs[1] = "test/fixtures/hh3-artifacts/contracts/test/contracts/Greeter.sol/Greeter.json";
        cpArgs[2] = string.concat(nestedDir, "/Stub.json");
        vm.ffi(cpArgs);

        ContractInfo memory info = Utils.getContractInfo("Stub.sol", spacesOutDir);

        assertEq(info.shortName, "Stub");
        assertTrue(info.artifactPath.startsWith(vm.projectRoot()), "artifactPath should be absolute");
        assertTrue(
            vm.contains(info.artifactPath, "dir with spaces/nested/Stub.sol/Stub.json"),
            "artifactPath should resolve through the spaces-containing outDir"
        );
    }
}
