# OpenZeppelin Defender integration

OpenZeppelin Foundry Upgrades can be used for performing deployments through [OpenZeppelin Defender](https://docs.openzeppelin.com/defender/v2/), which allows for features such as gas pricing estimation, resubmissions, and automated bytecode and source code verification.

> **Warning**
> Defender deployments are **always** broadcast to a live network, regardless of whether you are using the `broadcast` cheatcode.
> The recommended pattern is to separate Defender scripts from scripts that rely on network forking and simulations, to avoid mixing simulation and live network data.

> **Note**
> This is an experimental feature and its functionality is subject to change.

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
**Note**: Metadata must also be included in the compiler output, which it is by default.
3. Include `--ffi` in your `forge script` or `forge test` command.
4. Set the following environment variables in your `.env` file at your project root, using your Team API key and secret from OpenZeppelin Defender:
```
DEFENDER_KEY=<Your API key>
DEFENDER_SECRET<Your API secret>
```

## Usage

### Upgradeable Contracts

If you are deploying upgradeable contracts, use the `Upgrades` library as described in [README.md#usage](README.md#usage) but set the option `defender.useDefenderDeploy = true` when calling functions to cause all deployments to occur through OpenZeppelin Defender.

**Example:**

To deploy a UUPS proxy, create a script called `Defender.s.sol` like the following:
```
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MyContract} from "../src/MyContract.sol";

contract DefenderScript is Script {
    function setUp() public {}

    function run() public {
        Options memory opts;
        opts.defender.useDefenderDeploy = true;

        address proxy = Upgrades.deployUUPSProxy(
            "MyContract.sol",
            abi.encodeCall(MyContract.initialize, ("arguments for the initialize function")),
            opts
        );

        console.log("Deployed proxy to address", proxy);
    }
}
```

Then run the following command:
```
forge script <path to the script you created above> --ffi --rpc-url <RPC URL for the network you want to use>
```

The above example calls the `Upgrades.deployUUPSProxy` function with the `defender.useDefenderDeploy` option to deploy both the implementation contract and a UUPS proxy to the connected network using Defender. The function waits for the deployments to complete, which may take a few minutes per contract, then returns with the deployed proxy address. While the function is waiting, you can monitor your deployment status in OpenZeppelin Defender's [Deploy module](https://defender.openzeppelin.com/v2/#/deploy).

### Non-Upgradeable Contracts

If you are deploying non-upgradeable contracts, import the `Defender` library from [Defender.sol](src/Defender.sol) and use its functions to deploy contracts through OpenZeppelin Defender.

**Example:**

To deploy a non-upgradeable contract, create a script called `Defender.s.sol` like the following:
```
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Defender} from "openzeppelin-foundry-upgrades/Defender.sol";

contract DefenderScript is Script {
    function setUp() public {}

    function run() public {
        address deployed = Defender.deployContract("MyContract.sol", abi.encode("arguments for the constructor"));
        console.log("Deployed contract to address", deployed);
    }
}
```

Then run the following command:
```
forge script <path to the script you created above> --ffi --rpc-url <RPC URL for the network you want to use>
```

The above example calls the `Defender.deployContract` function to deploy the specified contract to the connected network using Defender. The function waits for the deployment to complete, which may take a few minutes, then returns with the deployed contract address. While the function is waiting, you can monitor your deployment status in OpenZeppelin Defender's [Deploy module](https://defender.openzeppelin.com/v2/#/deploy).
