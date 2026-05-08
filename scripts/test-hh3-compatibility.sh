#!/bin/bash
# Runs the HH3 compatibility test.
#
# Stages the minimal HH3 direct-lookup artifact fixture and build-info fixtures
# under a Hardhat 3-shaped tree, where build-info sits as a sibling of
# contracts/ rather than inside it. The fallback tests create their own nested
# copies during execution to exercise recursive lookup paths.

set -euo pipefail

# `artifacts/` is only a temporary HH3 staging area for this script. Leaving it
# behind makes later default-profile forge commands resolve implicit read access
# against `artifacts` instead of `out`.
cleanup() {
  rm -rf artifacts
}

trap cleanup EXIT

forge clean
cleanup

# Unique direct-lookup HH3 artifact fixture. Since no compiled source in this
# repo uses this name, Foundry will not overwrite it during `forge test`.
mkdir -p artifacts/contracts/HH3CompatibilityFixture.sol
cp test/fixtures/hh3-artifacts/contracts/contracts/HH3CompatibilityFixture.sol/HH3CompatibilityFixture.json \
   artifacts/contracts/HH3CompatibilityFixture.sol/HH3CompatibilityFixture.json

# Sibling of contracts/, not nested — HH3 convention.
mkdir -p artifacts/build-info
cp test/fixtures/hh3-artifacts/build-info/* artifacts/build-info/

# Export in shell; FOUNDRY_* vars aren't picked up if set from within tests.
export FOUNDRY_OUT=artifacts/contracts
export FOUNDRY_PROFILE=hh3-compatibility
forge test --match-contract HH3CompatibilityTest -vvv --ffi