# Security Baseline for QuantOS

## Operational rules

- Run the system with SELinux in enforcing mode.
- Default firewall policy: deny incoming unless explicitly allowed.
- Default outbound traffic allowed only for required services.
- Disable root SSH login.
- Use sudo with a secure policy and explicit privilege scope.
- Do not allow unrestricted admin delegation without validation.
- Use signed packages only.
- Require TPM-backed or secure boot-compatible boot verification where available.

## Default service policy

```text
Allowed by default:
- dbus
- systemd-journald
- udev
- polkit
- NetworkManager or systemd-networkd
- PipeWire
- display manager

Disallowed by default:
- insecure remote services
- anonymous package repos
- directories with shared writable access in privileged locations
- unrestricted sudoers entries
- debug services exposed to the network
```

## Hardening checklist

- systemd emergency shell disabled for non-admin access
- no passwordless local console admin
- no untrusted kernel modules loaded from removable media without explicit policy
- no default user with UID 0
- package manager configured to verify signatures before install
- log retention with access controls

## Security test cases

- Ensure the admin policy does not permit unauthenticated privilege escalation.
- Ensure `PermitRootLogin=no` is in place for SSH.
- Ensure SELinux mode is `enforcing`.
- Ensure package signature verification is enabled.
- Ensure the firewall blocks unsolicited inbound access.
