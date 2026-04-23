// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Utils, ContractInfo} from "openzeppelin-foundry-upgrades/internal/Utils.sol";
import {StringFinder} from "openzeppelin-foundry-upgrades/internal/StringFinder.sol";

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
 * which sets up the direct-lookup HH3 artifact fixture, HH3 build-info files,
 * and environment variables in the correct location. The fallback tests still
 * stage nested copies to exercise recursive lookup paths.
 *
 * Minimal HH3 fixtures:
 * This suite keeps only the HH3-specific fields that `Utils` actually reads,
 * so it remains a focused parser/layout regression test rather than duplicating
 * the full integration coverage that lives in the plugin-hardhat repo.
 */
contract HH3CompatibilityTest is Test {
    using StringFinder for string;

    string constant HH3_OUT_DIR = "artifacts/contracts";
    string constant HH3_CONTRACT_NAME = "HH3CompatibilityFixture.sol";
    string constant HH3_SHORT_NAME = "HH3CompatibilityFixture";
    string constant HH3_ABSOLUTE_PATH = "project/contracts/HH3CompatibilityFixture.sol";
    string constant HH3_CONTRACT_PATH = "contracts/HH3CompatibilityFixture.sol";
    string constant HH3_SOURCE_CODE_HASH = "0x9564e0245350d0eb5e42a8fed97d87518dbfbddf7668ed383f97a8558b2a9c39";
    string constant HH3_FIXTURE_ARTIFACT_PATH =
        "test/fixtures/hh3-artifacts/contracts/contracts/HH3CompatibilityFixture.sol/HH3CompatibilityFixture.json";
    string constant HH3_ARTIFACT_PATH = "artifacts/contracts/HH3CompatibilityFixture.sol/HH3CompatibilityFixture.json";
    string constant HH3_BUILD_INFO_OUTPUT_PATH =
        "artifacts/build-info/solc-0_8_29-907fbafcc0740e4f31aafd9a5fe5d66a6e55db92.output.json";

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
     * The script stages the direct-lookup HH3 fixture under artifacts/contracts,
     * so this test can call Utils.getContractInfo without any in-test copying.
     */
    function testGetContractInfo_withHH3Structure() public {
        assertTrue(vm.isFile(HH3_ARTIFACT_PATH), "HH3 fixture should be staged by the test script before lookup");

        ContractInfo memory info = Utils.getContractInfo(HH3_CONTRACT_NAME, HH3_OUT_DIR);
        string memory artifactJson = vm.readFile(info.artifactPath);

        assertEq(info.shortName, HH3_SHORT_NAME, "Contract name should match HH3 fixture");
        assertEq(info.contractPath, HH3_CONTRACT_PATH, "Contract path should match HH3 fixture");
        assertEq(
            info.sourceCodeHash,
            HH3_SOURCE_CODE_HASH,
            "Source code hash should come from the HH3 fixture metadata"
        );
        assertEq(
            info.artifactPath,
            string.concat(vm.projectRoot(), "/", HH3_ARTIFACT_PATH),
            "Artifact path should point to the staged HH3 fixture file"
        );
        assertEq(vm.parseJsonString(artifactJson, "._format"), "hh3-artifact-1", "Artifact should retain HH3 format");
        assertEq(
            vm.parseJsonString(artifactJson, ".inputSourceName"),
            HH3_ABSOLUTE_PATH,
            "Artifact should preserve the HH3 input source name"
        );
        assertEq(
            vm.parseJsonString(artifactJson, ".ast.absolutePath"),
            HH3_ABSOLUTE_PATH,
            "Artifact should preserve the HH3 absolute path"
        );
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
     * This verifies that the HH3 source hash resolves to the minimal build-info
     * fixture under artifacts/build-info/ rather than out/build-info/.
     */
    function testGetBuildInfoFile_withHH3Structure() public {
        assertTrue(vm.isFile(HH3_ARTIFACT_PATH), "HH3 fixture should be staged by the test script before lookup");

        ContractInfo memory contractInfo = Utils.getContractInfo(HH3_CONTRACT_NAME, HH3_OUT_DIR);
        string memory buildInfoFile = Utils.getBuildInfoFile(
            contractInfo.sourceCodeHash,
            contractInfo.shortName,
            HH3_OUT_DIR
        );

        assertEq(buildInfoFile, HH3_BUILD_INFO_OUTPUT_PATH, "Build-info path should resolve to the HH3 output fixture");

        // Verify this is actually an HH3 build-info file by checking its format
        string memory buildInfoJson = vm.readFile(buildInfoFile);
        assertTrue(vm.keyExistsJson(buildInfoJson, "._format"), "Build-info should have _format field");
        string memory format = vm.parseJsonString(buildInfoJson, "._format");
        assertEq(format, "hh3-sol-build-info-output-1", "Build-info should be HH3 output format");
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
        mkdirArgs[2] = "artifacts/contracts/nested-hh3-fixture/NestedHH3FallbackFixture.sol";
        vm.ffi(mkdirArgs);

        string[] memory cpArgs = new string[](3);
        cpArgs[0] = "cp";
        cpArgs[1] = HH3_FIXTURE_ARTIFACT_PATH;
        cpArgs[2] = "artifacts/contracts/nested-hh3-fixture/NestedHH3FallbackFixture.sol/NestedHH3FallbackFixture.json";
        vm.ffi(cpArgs);

        ContractInfo memory info = Utils.getContractInfo("NestedHH3FallbackFixture.sol", HH3_OUT_DIR);

        assertEq(info.shortName, "NestedHH3FallbackFixture");
        assertTrue(info.artifactPath.startsWith(vm.projectRoot()), "artifactPath should be absolute");
        assertTrue(
            vm.contains(
                info.artifactPath,
                "nested-hh3-fixture/NestedHH3FallbackFixture.sol/NestedHH3FallbackFixture.json"
            ),
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
        string memory nestedDir = string.concat(spacesOutDir, "/nested-hh3-fixture/SpacedHH3FallbackFixture.sol");

        string[] memory mkdirArgs = new string[](3);
        mkdirArgs[0] = "mkdir";
        mkdirArgs[1] = "-p";
        mkdirArgs[2] = nestedDir;
        vm.ffi(mkdirArgs);

        string[] memory cpArgs = new string[](3);
        cpArgs[0] = "cp";
        cpArgs[1] = HH3_FIXTURE_ARTIFACT_PATH;
        cpArgs[2] = string.concat(nestedDir, "/SpacedHH3FallbackFixture.json");
        vm.ffi(cpArgs);

        ContractInfo memory info = Utils.getContractInfo("SpacedHH3FallbackFixture.sol", spacesOutDir);

        assertEq(info.shortName, "SpacedHH3FallbackFixture");
        assertTrue(info.artifactPath.startsWith(vm.projectRoot()), "artifactPath should be absolute");
        assertTrue(
            vm.contains(
                info.artifactPath,
                "dir with spaces/nested-hh3-fixture/SpacedHH3FallbackFixture.sol/SpacedHH3FallbackFixture.json"
            ),
            "artifactPath should resolve through the spaces-containing outDir"
        );
    }
}
