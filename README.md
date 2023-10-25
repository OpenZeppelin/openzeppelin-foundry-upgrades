# OpenZeppelin Foundry Upgrades

Foundry library for deploying and managing upgradeable contracts, which includes upgrade safety checks.

> **Warning**
> Experimental code. This library is provided as a technology preview and its functionality may be subject to change.
> **Use at your own risk.**

## Installing Foundry

See [Foundry installation guide](https://book.getfoundry.sh/getting-started/installation).

## Installing the library

```
forge install OpenZeppelin/openzeppelin-foundry-upgrades
```

## Prerequisites

This library uses the [OpenZeppelin Upgrades Core CLI](https://docs.openzeppelin.com/upgrades-plugins/1.x/api-core) for upgrade safety checks. In order for safety checks to work, the following are required:
- Node.js must be installed.
- Configure your `foundry.toml` according to the [CLI Prerequisites](https://docs.openzeppelin.com/upgrades-plugins/1.x/api-core#foundry).
- If you are upgrading your contract from a previous version, add the `@custom:oz-upgrades-from <reference>` annotation to the new version of your contract according to [Define Reference Contracts](https://docs.openzeppelin.com/upgrades-plugins/1.x/api-core#define-reference-contracts) or specify the `referenceContract` option when calling the library's functions.
- Run `forge clean` before running your Foundry script or tests.
- Include `--ffi` in your `forge script` or `forge test` command.

If you do not want to run upgrade safety checks, use the `unsafeSkipAllChecks` option when calling the library's functions. Note that this is a dangerous option meant to be used as a last resort.

## Usage

Import the library:
```
import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
```

Then call functions from [Upgrades.sol](src/Upgrades.sol) to run validations, deployments, or upgrades.

## Contributing

### Running tests

```
forge clean && forge test --ffi
```

### Running example script

You can simulate deployments and upgrades of the various kinds of proxies by running the script:

```
forge clean && forge script test/Upgrades.s.sol --ffi
```

See [Solidity scripting guide](https://book.getfoundry.sh/tutorials/solidity-scripting) for more information.
