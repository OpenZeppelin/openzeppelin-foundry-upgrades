// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
  MyToken public instance;

  function setUp() public {
    instance = new MyToken();
  }

  function testName() public {
    assertEq(instance.name(), "MyToken");
  }
}
