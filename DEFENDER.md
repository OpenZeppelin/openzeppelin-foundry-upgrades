# OpenZeppelin Defender integration

OpenZeppelin Foundry Upgrades be used for performing deployments through OpenZeppelin Defender.

## Installing

See [README.md#installing](README.md#installing)

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

> **Warning**
> Defender deployments are **always** broadcast to a live network, regardless of whether you are using the `broadcast` cheatcode.
> The recommended pattern is to separate Defender scripts from scripts that rely on network forking and simulations, to avoid mixing simulation and live network data.

> **Note**
> This is an experimental feature and its functionality is subject to change.
> Deployments are currently limited to non-upgradeable contracts without constructor arguments. Additional enhancements are coming soon to expand upon this.

## Example

After performing the prerequisites above, create a script similar to [Defender.s.sol](test/Defender.s.sol).

Then run the following command:
```
forge script <path to the script you created above> --ffi --rpc-url <RPC URL for the network you want to use>
```

The script calls `Defender.deployContract(contractName)` to deploy the specified contract to the connected network using Defender. The function waits for deployment to complete, which may take a few minutes, then returns with the deployed address. While the function is waiting, you can monitor your deployment status in OpenZeppelin Defender's [Deploy module](https://defender.openzeppelin.com/v2/#/deploy).