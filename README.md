# QuantOS

QuantOS is a Fedora-based Linux desktop distribution designed around the requirements in `custom-linux-distro-prd.md`.

## Real build workflow

This repository now contains the actual ISO build pipeline needed for a Fedora-based host:

- `build/prepare-host.sh` installs the Fedora live-media tooling
- `build/quantos.ks` is the Kickstart file used to assemble the system image
- `build/build-iso.sh` creates the ISO with `livemedia-creator`
- `Makefile` exposes the common build command

## Build commands

On a Fedora 40+ host:

```bash
sudo bash build/prepare-host.sh
sudo bash build/build-iso.sh --output-dir ./output --arch x86_64
```

or:

```bash
make build
```

The `make build` target runs the ISO script in help mode unless the environment is configured for a real generation run.

## Security posture

This distribution follows the PRD security model:

- SELinux enforced
- secure boot support planned
- LUKS2 full-disk encryption option
- firewall enabled
- signed package policy
- no passwordless admin delegation
- no root SSH login
- minimal, auditable services

## Important note

This repository contains the real build scaffolding for an actual Fedora ISO, but the ISO itself cannot be generated in this Windows environment without a Fedora build host and root privileges.
