#!/usr/bin/env bash

set -euo pipefail

export FOUNDRY_PROFILE=build-v1
forge build --force

rm -rf test_artifacts
mkdir -p test_artifacts/build-info-v1
mv out/build-info/*.json test_artifacts/build-info-v1

export FOUNDRY_PROFILE=build-v2
forge test -vvv --ffi --force

export FOUNDRY_PROFILE=build-v2-bad
forge test -vvv --ffi --force