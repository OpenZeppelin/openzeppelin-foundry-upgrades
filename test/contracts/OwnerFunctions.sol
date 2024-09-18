// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// These contracts are for testing only, they are not safe for use in production.

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract HasOwner is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}
}

contract NoGetter {}

contract StringOwner {
    string public owner;

    constructor(string memory initialOwner) {
        owner = initialOwner;
    }
}

contract StateChanging {
    bool public triggered;

    function owner() public {
        triggered = true;
    }
}
