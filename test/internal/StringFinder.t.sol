// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {StringFinder} from "openzeppelin-foundry-upgrades/internal/StringFinder.sol";

/**
 * @dev Tests the StringFinder internal library.
 */
contract StringFinderTest is Test {
    using StringFinder for string;

    function testContains() public {
        string memory str = "hello world";
        assertTrue(str.contains("ello"));
        assertFalse(str.contains("Ello"));
    }

    function testStartsWith() public {
        string memory str = "hello world";
        assertTrue(str.startsWith("hello"));
        assertFalse(str.startsWith("ello"));
        assertFalse(str.startsWith("Hello"));
    }

    function testEndsWith() public {
        string memory str = "hello world";
        assertTrue(str.endsWith("world"));
        assertFalse(str.endsWith("worl"));
        assertFalse(str.endsWith("World"));
    }

    function testCount() public {
        string memory str = "hello world";
        assertEq(str.count("l"), 3);
        assertEq(str.count("ll"), 1);
        assertEq(str.count("a"), 0);
    }
}
