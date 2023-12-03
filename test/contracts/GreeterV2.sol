// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// These contracts are for testing only, they are not safe for use in production.

/// @custom:oz-upgrades-from Greeter
contract GreeterV2 {
    string public greeting;


    // For production usage, you may want to add `reinitializer(2)` from the openzepplin `Initializable` contract for the 2nd initialization function.
    function resetGreeting() public {
        greeting = "resetted";
    }
}
