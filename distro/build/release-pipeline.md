# Release Pipeline Baseline

## Build and release requirements

- ISO builds are automated and reproducible
- release artifacts are checksummed and signed
- package repositories use explicit promotion: development -> testing -> stable
- kernel and desktop updates are validated before broad rollout
- rollback and recovery flow is tested in CI

## Required validation stages

1. Build validation
2. Boot validation in QEMU
3. Desktop session validation
4. Update and rollback verification
5. Regression checks

## Release policy

- security updates are prioritized and promoted quickly
- major system changes require longer validation
- unstable packages remain isolated from stable users
- all release metadata must be traceable to signed source artifacts
