# Changelog

## Unreleased

- Support constructor arguments for Defender deployments. ([#16](https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades/pull/16))
- Support Defender deployments for upgradeable contracts. ([#18](https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades/pull/18))

### Breaking changes
- `Defender.deployContract` functions now return `address` instead of `string`.
- Defender deployments now require metadata to be included in compiler output.
- Defender deployments no longer print console output on successful deployments.

## 0.0.1 (2024-02-06)

- Initial preview