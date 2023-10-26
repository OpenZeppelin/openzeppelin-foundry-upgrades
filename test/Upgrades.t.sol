// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

import {MyToken} from "./contracts/MyToken.sol";
import {MyTokenV2} from "./contracts/MyTokenV2.sol";
import {MyTokenProxiable} from "./contracts/MyTokenProxiable.sol";
import {MyTokenProxiableV2} from "./contracts/MyTokenProxiableV2.sol";
import {WithConstructor} from "./contracts/WithConstructor.sol";

contract UpgradesTest is Test {
    address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function testUUPS() public {
        address proxy = Upgrades.deployUUPSProxy(
            "MyTokenProxiable.sol",
            abi.encodeCall(MyTokenProxiable.initialize, ("hello", msg.sender))
        );
        MyToken instance = MyToken(proxy);
        address implAddressV1 = Upgrades.getImplementationAddress(proxy);

        assertEq(instance.name(), "MyToken");
        assertEq(instance.greeting(), "hello");
        assertEq(instance.owner(), msg.sender);

        Upgrades.upgradeProxy(
            proxy,
            "MyTokenProxiableV2.sol",
            abi.encodeCall(MyTokenProxiableV2.resetGreeting, ()),
            msg.sender
        );
        address implAddressV2 = Upgrades.getImplementationAddress(proxy);

        assertEq(instance.greeting(), "resetted");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testTransparent() public {
        address proxy = Upgrades.deployTransparentProxy(
            "MyToken.sol",
            msg.sender,
            abi.encodeCall(MyToken.initialize, ("hello", msg.sender))
        );
        MyToken instance = MyToken(proxy);
        address implAddressV1 = Upgrades.getImplementationAddress(proxy);
        address adminAddress = Upgrades.getAdminAddress(proxy);

        assertFalse(adminAddress == address(0));

        assertEq(instance.name(), "MyToken");
        assertEq(instance.greeting(), "hello");
        assertEq(instance.owner(), msg.sender);

        Upgrades.upgradeProxy(proxy, "MyTokenV2.sol", abi.encodeCall(MyTokenV2.resetGreeting, ()), msg.sender);
        address implAddressV2 = Upgrades.getImplementationAddress(proxy);

        assertEq(Upgrades.getAdminAddress(proxy), adminAddress);

        assertEq(instance.greeting(), "resetted");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testBeacon() public {
        address beacon = Upgrades.deployBeacon("MyToken.sol", msg.sender);
        address implAddressV1 = IBeacon(beacon).implementation();

        address proxy = Upgrades.deployBeaconProxy(beacon, abi.encodeCall(MyToken.initialize, ("hello", msg.sender)));
        MyToken instance = MyToken(proxy);

        assertEq(Upgrades.getBeaconAddress(proxy), beacon);

        assertEq(instance.name(), "MyToken");
        assertEq(instance.greeting(), "hello");
        assertEq(instance.owner(), msg.sender);

        Upgrades.upgradeBeacon(beacon, "MyTokenV2.sol", msg.sender);
        address implAddressV2 = IBeacon(beacon).implementation();

        MyTokenV2(address(instance)).resetGreeting();

        assertEq(instance.greeting(), "resetted");
        assertFalse(implAddressV2 == implAddressV1);
    }

    function testUpgradeProxyWithoutCaller() public {
        address proxy = Upgrades.deployUUPSProxy(
            "MyTokenProxiable.sol",
            abi.encodeCall(MyTokenProxiable.initialize, ("hello", msg.sender))
        );

        Vm vm = Vm(CHEATCODE_ADDRESS);
        vm.startPrank(msg.sender);
        Upgrades.upgradeProxy(proxy, "MyTokenProxiableV2.sol", abi.encodeCall(MyTokenProxiableV2.resetGreeting, ()));
        vm.stopPrank();
    }

    function testUpgradeBeaconWithoutCaller() public {
        address beacon = Upgrades.deployBeacon("MyToken.sol", msg.sender);

        Vm vm = Vm(CHEATCODE_ADDRESS);
        vm.startPrank(msg.sender);
        Upgrades.upgradeBeacon(beacon, "MyTokenV2.sol");
        vm.stopPrank();
    }

    function testValidateImplementation() public {
        Options memory opts;
        Validator v = new Validator();
        try v.validateImplementation("Validations.sol:Unsafe", opts) {
            fail();
        } catch {
            // TODO: check error message
        }
    }

    function testValidateLayout() public {
        Options memory opts;
        opts.referenceContract = "Validations.sol:LayoutV1";
        Validator v = new Validator();
        try v.validateUpgrade("Validations.sol:LayoutV2_Bad", opts) {
            fail();
        } catch {
            // TODO: check error message
        }
    }

    function testValidateLayoutUpgradesFrom() public {
        Options memory opts;
        Validator v = new Validator();
        try v.validateUpgrade("Validations.sol:LayoutV2_UpgradesFrom_Bad", opts) {
            fail();
        } catch {
            // TODO: check error message
        }
    }

    function testValidateNamespaced() public {
        Options memory opts;
        opts.referenceContract = "Validations.sol:NamespacedV1";
        Validator v = new Validator();
        try v.validateUpgrade("Validations.sol:NamespacedV2_Bad", opts) {
            fail();
        } catch {
            // TODO: check error message
        }
    }

    function testValidateNamespacedUpgradesFrom() public {
        Options memory opts;
        Validator v = new Validator();
        try v.validateUpgrade("Validations.sol:NamespacedV2_UpgradesFrom_Bad", opts) {
            fail();
        } catch {
            // TODO: check error message
        }
    }

    function testValidateNamespacedOk() public {
        Options memory opts;
        opts.referenceContract = "Validations.sol:NamespacedV1";
        Upgrades.validateUpgrade("Validations.sol:NamespacedV2_Ok", opts);
    }

    function testValidateNamespacedUpgradesFromOk() public {
        Options memory opts;
        Upgrades.validateUpgrade("Validations.sol:NamespacedV2_UpgradesFrom_Ok", opts);
    }

    function testValidateNamespacedNoReference() public {
        Options memory opts;
        Validator v = new Validator();
        // validate upgrade without reference contract - an error is expected from upgrades-core CLI
        try v.validateUpgrade("Validations.sol:NamespacedV2_Ok", opts) {
            fail();
        } catch {
            // TODO: check error message
        }
    }

    function testUnsafeSkipAllChecks() public {
        Options memory opts;
        opts.unsafeSkipAllChecks = true;
        Upgrades.validateImplementation("Validations.sol:Unsafe", opts);
    }

    function testUnsafeSkipStorageCheck() public {
        Options memory opts;
        opts.unsafeSkipStorageCheck = true;
        Upgrades.validateUpgrade("Validations.sol:NamespacedV2_UpgradesFrom_Bad", opts);
    }

    function testUnsafeAllow() public {
        Options memory opts;
        opts.unsafeAllow = "delegatecall,selfdestruct";
        Upgrades.validateImplementation("Validations.sol:Unsafe", opts);
    }

    // TODO
    // function testUnsafeAllowRenames()

    // TODO fix this in upgrades-core
    // function testSkipStorageCheckNoReference() public {
    //   Options memory opts;
    //   opts.unsafeSkipStorageCheck = true;
    //   Upgrades.validateUpgrade("Validations.sol:NamespacedV2_Ok", opts);
    // }

    function testWithConstructor() public {
        Options memory opts;
        opts.constructorData = abi.encode(123);
        address proxy = Upgrades.deployTransparentProxy("WithConstructor.sol", msg.sender, abi.encodeCall(WithConstructor.initialize, (456)), opts);
        assertEq(WithConstructor(proxy).a(), 123);
        assertEq(WithConstructor(proxy).b(), 456);
    }
}

contract Validator {
    function validateImplementation(string memory contractName, Options memory opts) public {
        Upgrades.validateImplementation(contractName, opts);
    }

    function validateUpgrade(string memory contractName, Options memory opts) public {
        Upgrades.validateUpgrade(contractName, opts);
    }
}
