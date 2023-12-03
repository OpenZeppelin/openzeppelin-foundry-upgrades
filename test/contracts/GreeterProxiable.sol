// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Proxiable} from "./Proxiable.sol";

// These contracts are for testing only, they are not safe for use in production.

contract GreeterProxiable is Proxiable {
    string public greeting;

    // For production usage, you may want to add `initializer` from the openzepplin `Initializable` contract.
    function initialize(string memory _greeting) public {
        greeting = _greeting;
    }
}
