# OpenZeppelin Defender integration

## Prerequisites
1. Install [Node.js](https://nodejs.org/).
2. Configure your `foundry.toml` to include build info and storage layout:
```
[profile.default]
build_info = true
extra_output = ["storageLayout"]
```
3. Include `--ffi` in your `forge script` or `forge test` command.
4. Set the following environment variables in your `.env` file at your project root, using your Team API key and secret from OpenZeppelin Defender:
```
DEFENDER_KEY=<Your API key>
DEFENDER_SECRET<Your API secret>
```

## Usage

Import the Defender library in your Foundry scripts or tests:
```
import {Defender} from "openzeppelin-foundry-upgrades/Defender.sol";
```

Then call functions from [Defender.sol](src/Defender.sol) to deploy contracts through OpenZeppelin Defender.

> **Note**
> This is an experimental feature and its functionality is subject to change.
> Deployments are currently limited to non-upgradeable contracts without constructors. Additional enhancements are coming soon to allow more use-cases.