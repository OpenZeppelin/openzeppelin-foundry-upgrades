#!/bin/bash
# scripts/test-hh3-compatibility.sh
# Script para rodar o teste de compatibilidade HH3

set -e

mkdir -p artifacts/contracts/test/contracts/Greeter.sol
cp test/fixtures/hh3-artifacts/contracts/test/contracts/Greeter.sol/Greeter.json \
   artifacts/contracts/test/contracts/Greeter.sol/Greeter.json

mkdir -p artifacts/build-info
cp test/fixtures/hh3-artifacts/build-info/* artifacts/build-info/

export FOUNDRY_OUT=artifacts/contracts
export FOUNDRY_PROFILE=hh3-compatibility
forge test --match-contract HH3CompatibilityTest -vvv --ffi --force