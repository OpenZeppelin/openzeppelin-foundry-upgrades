# Foundry Upgrades (Preview)

Preview of a Foundry library for deploying and managing upgradeable contracts, which includes upgrade safety checks.

> **Warning**
> Experimental code. Functionality is subject to change.
> **Use at your own risk.**

## Installing Foundry

See [Foundry installation guide](https://book.getfoundry.sh/getting-started/installation).

## Installing the library

```
forge install <URL of this GitHub repository>
```

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

### Running test script

You can simulate a deployment by running the script:

```
forge clean && forge script test/Upgrades.s.sol --ffi
```

See [Solidity scripting guide](https://book.getfoundry.sh/tutorials/solidity-scripting) for more information.
