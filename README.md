# Foundry Upgrades Preview

Preview Foundry library for deploying and managing upgradeable contracts, which includes upgrade safety checks.

> **Warning**
> Experimental code. Functionality is subject to change.
> **Use at your own risk.**

## Installing Foundry

See [Foundry installation guide](https://book.getfoundry.sh/getting-started/installation).

## Running tests

```
forge clean && forge test --ffi
```

## Running scripts

You can simulate a deployment by running the script:

```
forge clean && forge script script/MyToken.s.sol --ffi
```

See [Solidity scripting guide](https://book.getfoundry.sh/tutorials/solidity-scripting) for more information.
