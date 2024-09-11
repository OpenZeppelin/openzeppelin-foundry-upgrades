# OpenZeppelin Foundry Upgrades

[![Docs](https://img.shields.io/badge/docs-%F0%9F%93%84-blue)](https://docs.openzeppelin.com/upgrades-plugins/foundry-upgrades)

Foundry library for deploying and managing upgradeable contracts, which includes upgrade safety validations.

## Installing

Follow one of the sections below depending on which version of OpenZeppelin Contracts you are using. OpenZeppelin Contracts v5 is required for new deployments.

### Using OpenZeppelin Contracts v5

Run these commands:
```console
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-foundry-upgrades
forge install OpenZeppelin/openzeppelin-contracts-upgradeable
```

Set the following in `remappings.txt`, replacing any previous definitions of these remappings:
```
@openzeppelin/contracts/=lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/
@openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/
```

> **Note**
> The above remappings mean that both `@openzeppelin/contracts/` (including proxy contracts deployed by this library) and `@openzeppelin/contracts-upgradeable/` come from your installation of the `openzeppelin-contracts-upgradeable` submodule and its subdirectories, which includes its own transitive copy of `openzeppelin-contracts` of the same release version number. This format is needed for Etherscan verification to work. Particularly, any copies of `openzeppelin-contracts` that you install separately are NOT used.

### Using OpenZeppelin Contracts v4

Run these commands, replacing `v4.9.6` with the specific version of OpenZeppelin Contracts that you are using:
```console
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-foundry-upgrades
forge install OpenZeppelin/openzeppelin-contracts@v4.9.6
forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v4.9.6
```

Set the following in `remappings.txt`:
```
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
@openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/
```

> **Note**
> Use [LegacyUpgrades.sol](src/LegacyUpgrades.sol) instead of `Upgrades.sol` to upgrade existing deployments that were created with OpenZeppelin Contracts v4.

## OpenZeppelin Defender integration

See [DEFENDER.md](DEFENDER.md)

## Foundry Requirements

This library requires [forge-std](https://github.com/foundry-rs/forge-std) version 1.8.0 or higher.

## Before Running

This library uses the [OpenZeppelin Upgrades CLI](https://docs.openzeppelin.com/upgrades-plugins/1.x/api-core) for upgrade safety validations, which are run by default during deployments and upgrades.

If you want to be able to run upgrade safety validations, the following are needed:
1. Install [Node.js](https://nodejs.org/).
2. Configure your `foundry.toml` to enable ffi, ast, build info and storage layout:
```toml
[profile.default]
ffi = true
ast = true
build_info = true
extra_output = ["storageLayout"]
```
3. If you are upgrading your contract from a previous version, add the `@custom:oz-upgrades-from <reference>` annotation to the new version of your contract according to [Define Reference Contracts](https://docs.openzeppelin.com/upgrades-plugins/1.x/api-core#define-reference-contracts) or specify the `referenceContract` option when calling the library's functions.
4. Run `forge clean` before running your Foundry script or tests, or include the `--force` option when running `forge script` or `forge test`.

If you do not want to run upgrade safety validations, you can skip the above steps and use the [`unsafeSkipAllChecks` option](src/Options.sol) when calling the `Upgrades` library's functions, or use the `UnsafeUpgrades` library instead. Note that these are dangerous options meant to be used as a last resort.

### Optional: Custom output directory

By default, this library assumes your Foundry output directory is set to "out".

If you want to use a custom output directory, set it in your `foundry.toml` and provide read permissions for the directory. For example (replace `my-output-dir` with the directory that you want to use):
```toml
[profile.default]
out = "my-output-dir"
fs_permissions = [{ access = "read", path = "my-output-dir" }]
```
Then in a `.env` at your project root, set the `FOUNDRY_OUT` environment variable to match the custom output directory, for example:
```env
FOUNDRY_OUT=my-output-dir
```

### Windows environments

If you are using Windows, set the `OPENZEPPELIN_BASH_PATH` environment variable to the fully qualified path of the `bash` executable.
For example, if you are using [Git for Windows](https://gitforwindows.org/), add the following line in the `.env` file of your project (using forward slashes):
```env
OPENZEPPELIN_BASH_PATH="C:/Program Files/Git/bin/bash"
```

## Usage

Depending on which major version of OpenZeppelin Contracts you are using, and whether you want to run upgrade safety validations and/or use OpenZeppelin Defender, use the table below to determine which library to import:

|     | OpenZeppelin Contracts v5 | OpenZeppelin Contracts v4 |
| --- | --- | --- |
| **Runs validations, supports Defender** | `import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";` | `import {Upgrades} from "openzeppelin-foundry-upgrades/LegacyUpgrades.sol";` |
| **No validations, does not support Defender** | `import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";` | `import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/LegacyUpgrades.sol";` |


Import one of the above libraries in your Foundry scripts or tests, for example:
```solidity
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
```

Also import the implementation contract that you want to validate, deploy, or upgrade to, for example:
```solidity
import {MyToken} from "src/MyToken.sol";
```

Then call functions from the imported library to run validations, deployments, or upgrades.

### Examples

The following examples assume you are using OpenZeppelin Contracts v5 and want to run upgrade safety validations.

Deploy a UUPS proxy:
```solidity
address proxy = Upgrades.deployUUPSProxy(
    "MyContract.sol",
    abi.encodeCall(MyContract.initialize, ("arguments for the initialize function"))
);
```

Deploy a transparent proxy:
```solidity
address proxy = Upgrades.deployTransparentProxy(
    "MyContract.sol",
    INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN,
    abi.encodeCall(MyContract.initialize, ("arguments for the initialize function"))
);
```

Call your contract's functions as normal, but remember to always use the proxy address:
```solidity
MyContract instance = MyContract(proxy);
instance.myFunction();
```

Upgrade a transparent or UUPS proxy and call an arbitrary function (such as a reinitializer) during the upgrade process:
```solidity
Upgrades.upgradeProxy(
    transparentProxy,
    "MyContractV2.sol",
    abi.encodeCall(MyContractV2.foo, ("arguments for foo"))
);
```

Upgrade a transparent or UUPS proxy without calling any additional function:
```solidity
Upgrades.upgradeProxy(
    transparentProxy,
    "MyContractV2.sol",
    ""
);
```

> **Warning**
> When upgrading a proxy or beacon, ensure that the new contract either has its `@custom:oz-upgrades-from <reference>` annotation set to the current implementation contract used by the proxy or beacon, or set it with the `referenceContract` option, for example:
> ```solidity
> Options memory opts;
> opts.referenceContract = "MyContractV1.sol";
> Upgrades.upgradeProxy(proxy, "MyContractV2.sol", "", opts);
> // or Upgrades.upgradeBeacon(beacon, "MyContractV2.sol", opts);
> ```

Deploy an upgradeable beacon:
```solidity
address beacon = Upgrades.deployBeacon("MyContract.sol", INITIAL_OWNER_ADDRESS_FOR_BEACON);
```

Deploy a beacon proxy:
```solidity
address proxy = Upgrades.deployBeaconProxy(
    beacon,
    abi.encodeCall(MyContract.initialize, ("arguments for the initialize function"))
);
```

Upgrade a beacon:
```solidity
Upgrades.upgradeBeacon(beacon, "MyContractV2.sol");
```

### Contract name formats

#### Foundry artifact format
Applies to:
- `contractName` parameter
- `referenceContract` option

When using functions that take a contract name, or the `referenceContract` option, the string must be in one of the following formats (to be compliant with Foundry's [getCode](https://book.getfoundry.sh/cheatcodes/get-code) cheatcode):
- the Solidity file name, e.g. `ContractV1.sol`
- the Solidity file name and the contract name, e.g. `ContractV1.sol:ContractV1`
- the artifact path relative to the project root directory, e.g. `out/ContractV1.sol/ContractV1.json`

#### Annotation format
Applies to:
- `@custom:oz-upgrades-from <reference>` annotation

When using the `@custom:oz-upgrades-from <reference>` annotation, the reference contract name must be in one of the following formats (to be compliant with the [OpenZeppelin Upgrades CLI](https://docs.openzeppelin.com/upgrades-plugins/api-core#define-reference-contracts)):
- the contract name, e.g. `ContractV1`
- fully qualified contract name, e.g. `contracts/tokens/ContractV1.sol:ContractV1`

If the `referenceBuildInfoDir` option is set, use one of the following formats:
- the reference build info directory name and the contract name, e.g. `build-info-v1:ContractV1`
- the reference build info directory name and the fully qualified contract name, e.g. `build-info-v1:contracts/tokens/ContractV1.sol:ContractV1`

### Coverage Testing

To enable code coverage reports with `forge coverage`, use the following deployment pattern in your tests: instantiate your implementation contracts directly and use the `UnsafeUpgrades` library. For example:
```solidity
address implementation = address(new MyContract());
address proxy = Upgrades.deployUUPSProxy(
    implementation,
    abi.encodeCall(MyContract.initialize, ("arguments for the initialize function"))
);
```

> **Warning**
`UnsafeUpgrades` is not recommended for use in Forge scripts. It does not validate whether your contracts are upgrade safe or whether new implementations are compatible with previous ones. Ensure you run validations before any actual deployments or upgrades, such as by using the `Upgrades` library in scripts.

### Deploying and Verifying

Run your script with `forge script` to broadcast and deploy. See Foundry's [Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting) guide.

> **Important**
> Include the `--sender <ADDRESS>` flag for the `forge script` command when performing upgrades, specifying an address that owns the proxy or proxy admin. Otherwise, `OwnableUnauthorizedAccount` errors will occur.

> **Note**
> Include the `--verify` flag for the `forge script` command if you want to verify source code such as on Etherscan. This will verify your implementation contracts along with any proxy contracts as part of the deployment.
