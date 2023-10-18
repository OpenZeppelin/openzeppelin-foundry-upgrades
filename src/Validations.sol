// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Unsafe {
    function unsafe() public {
        selfdestruct(payable(msg.sender));
    }
}

contract LayoutV1 {
    uint256 a;
    uint256 b;
}

contract LayoutV2 {
    uint256 a;
}

/// @custom:oz-upgrades-from LayoutV1
contract LayoutV2_Reference {
    uint256 a;
}