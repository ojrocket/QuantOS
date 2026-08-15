# QuantOS Architecture

## 1. Design direction

QuantOS follows the PRD direction for a Fedora-based desktop distribution with a polished, secure, predictable user experience. The architecture is intentionally conservative and heavily informed by proven upstream patterns.

## 2. Platform baseline

- OS base: Fedora Linux
- CPU: x86_64 initially
- Filesystem: ext4 by default
- Desktop: Hyprland on Wayland
- Init system: systemd
- Boot: UEFI with bootloader selection after evaluation
- Security: SELinux, firewall, Secure Boot, LUKS2, signed packages
- Updates: preferred atomic rollback via OSTree / rpm-ostree, with DNF/RPM fallback if needed

## 3. System layers

```text
UEFI
  -> bootloader
  -> Linux kernel
  -> initramfs
  -> systemd
  -> userspace services
  -> graphical session (Hyprland)
  -> applications
```

## 4. Security boundaries

- OS partition is read-only or versioned in atomic mode
- /home remains user data and persistent personalization
- user privileges are separated from admin actions
- services follow least privilege and systemd sandboxing patterns
- all package, kernel, and image updates are verified before deployment

## 5. Packaging strategy

Preferred:

- rpm-ostree for atomic system images and rollback
- signed Fedora repositories
- Flatpak for third-party desktop apps

Fallback:

- DNF/RPM direct installs
- package channels for development, testing, stable

## 6. Recovery model

The system must recover from:

- failed package updates
- broken GPU drivers
- failed kernel upgrades
- bad desktop configuration
- boot failure

The preferred solution is to use deployment-based rollback with OSTree and a bootable previous deployment. Fallback recovery requires an offline recovery image and a validated rollback path.

## 7. Operational model

- Minimal background services
- explicit update channel promotion
- signed release artifacts
- CI boot verification and regression checks
- system health diagnosis via `distro doctor`
