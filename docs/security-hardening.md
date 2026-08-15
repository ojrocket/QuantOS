# Security Hardening Baseline

## Security principles

1. Secure defaults over permissive defaults.
2. Least privilege for all users and services.
3. Signed artifacts only.
4. Recovery by design.
5. Minimal attack surface.

## Baseline controls

- SELinux enabled and enforced
- Secure Boot support where the platform supports it
- LUKS2 optional full-disk encryption support
- UEFI-only boot flow preferred
- firewall enabled by default
- no root login via console or SSH
- no passwordless sudo rules
- package signatures required
- no directories with broadly shared writable access outside explicitly approved temporary locations
- kernel hardening enabled (`nosmt`, `slab_nomerge`, `lockdown=integrity` where appropriate)
- `umask 027` for default file creation

## System defaults

```ini
# Example hardened defaults for a Fedora-derived system
SELINUX=enforcing
SELINUXTYPE=targeted
FirewallBackend=nftables
PasswordAuthentication=no
KbdInteractiveAuthentication=no
PermitRootLogin=no
```

## Service minimization

The OS should avoid broad background service sprawl; only the following categories should remain enabled by default:

- systemd journal
- network manager or networkd
- udev
- polkit
- display manager
- audio services
- bluetooth services only when required

## Update and release security

- all packages must be GPG-signed
- release artifacts must carry checksums
- ISO verification must happen before installation
- update channels must be explicit: development, testing, stable
- high-risk updates must require review and validation before promotion

## Recovery requirements

- previous deployment rollback must be tested
- kernel and GPU recovery must be tested in CI
- installer must support rollback and rescue boot flows
- diagnostics must explain local security state without exposing private information
