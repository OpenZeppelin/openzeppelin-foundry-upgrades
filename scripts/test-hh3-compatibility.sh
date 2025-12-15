#!/bin/bash
# scripts/test-hh3-compatibility.sh
# Script para rodar o teste de compatibilidade HH3

set -e

mkdir -p artifacts/contracts/test/contracts/Greeter.sol
cp test/fixtures/hh3-artifacts/contracts/test/contracts/Greeter.sol/Greeter.json \
   artifacts/contracts/test/contracts/Greeter.sol/Greeter.json

export FOUNDRY_OUT=artifacts/contracts
forge test --match-contract HH3CompatibilityTest -vvv --ffi --force 
