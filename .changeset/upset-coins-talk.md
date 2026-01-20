---
'@openzeppelin/foundry-upgrades': minor
---

Add support for Hardhat 3 compatibility, including enhanced build info directory handling and artifact path resolution. The library now automatically detects the build environment and uses Hardhat 3's build-info directory structure (`artifacts/build-info`) when `FOUNDRY_OUT` is set to a non-default value (e.g., `artifacts/contracts`), and properly handles Hardhat 3 artifact format with canonical path names by removing the `project/` prefix when present.
