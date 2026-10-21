// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// These contracts are for testing only, they are not safe for use in production.

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Proxy that allows deployment with empty initializer data
contract UnsafeAllowUninitializedProxy is ERC1967Proxy {
    constructor(address implementation, bytes memory data) ERC1967Proxy(implementation, data) {}

    function _unsafeAllowUninitialized() internal pure override returns (bool) {
        return true;
    }
}
