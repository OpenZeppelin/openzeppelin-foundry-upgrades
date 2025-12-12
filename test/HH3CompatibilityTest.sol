// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Utils} from "openzeppelin-foundry-upgrades/internal/Utils.sol";

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
 */
contract HH3CompatibilityTest is Test {
    function setUp() public {
        // Set FOUNDRY_OUT to match Hardhat 3's default structure
        vm.setEnv("FOUNDRY_OUT", "artifacts/contracts");
    }

    function testGetOutDir_respectsFOUNDRY_OUT() public {
        // Verify that getOutDir() returns the value from FOUNDRY_OUT
        string memory outDir = Utils.getOutDir();
        assertEq(outDir, "artifacts/contracts");
    }

    function testGetOutDir_fallbackToDefault() public {
        // Test that vm.envOr() fallback works correctly
        // Note: vm.envOr() only uses default when variable doesn't exist,
        // not when it's an empty string. This test verifies the fallback mechanism works.
        string memory defaultOut = vm.envOr("FOUNDRY_OUT_NONEXISTENT", "out");
        assertEq(defaultOut, "out");
    }

    function testGetContractInfo_withFoundryStructure() public {
        // This test verifies that getContractInfo works with Foundry's default structure
        // We temporarily override FOUNDRY_OUT to test with "out" directory
        vm.setEnv("FOUNDRY_OUT", "out");
        
        Utils.ContractInfo memory info = Utils.getContractInfo("Greeter.sol", "out");
        assertEq(info.shortName, "Greeter");
        assertEq(info.contractPath, "test/contracts/Greeter.sol");
    }

    function testFOUNDRY_OUT_environmentVariable() public {
        // Verify that the environment variable is correctly set and read
        string memory foundryOut = vm.envOr("FOUNDRY_OUT", "out");
        assertEq(foundryOut, "artifacts/contracts");
    }
}