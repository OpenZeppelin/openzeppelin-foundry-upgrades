#!/bin/bash
# Runs the HH3 compatibility test.
#
# Stages a Hardhat 3-shaped artifact tree where build-info sits as a sibling
# of contracts/, not nested inside it (Foundry's native layout nests them).

set -e

mkdir -p artifacts/contracts/test/contracts/Greeter.sol
cp test/fixtures/hh3-artifacts/contracts/test/contracts/Greeter.sol/Greeter.json \
   artifacts/contracts/test/contracts/Greeter.sol/Greeter.json

# Sibling of contracts/, not nested — HH3 convention.
mkdir -p artifacts/build-info
cp test/fixtures/hh3-artifacts/build-info/* artifacts/build-info/

# Export in shell; FOUNDRY_* vars aren't picked up if set from within tests.
export FOUNDRY_OUT=artifacts/contracts
export FOUNDRY_PROFILE=hh3-compatibility
forge test --match-contract HH3CompatibilityTest -vvv --ffi --force