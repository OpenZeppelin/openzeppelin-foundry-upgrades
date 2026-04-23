#!/bin/bash
# Runs the HH3 compatibility test.
#
# Stages the minimal HH3 build-info fixtures under a Hardhat 3-shaped tree,
# where build-info sits as a sibling of contracts/ rather than inside it.
# These tests stage their own uniquely named HH3 artifact fixtures
# after compilation so they only exercise the HH3 compatibility path.

set -e

# Sibling of contracts/, not nested — HH3 convention.
mkdir -p artifacts/build-info
cp test/fixtures/hh3-artifacts/build-info/* artifacts/build-info/

# Export in shell; FOUNDRY_* vars aren't picked up if set from within tests.
export FOUNDRY_OUT=artifacts/contracts
export FOUNDRY_PROFILE=hh3-compatibility
forge test --match-contract HH3CompatibilityTest -vvv --ffi --force