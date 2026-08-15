# Custom Linux Distribution — Product Requirements Document

**Status:** Draft v0.1
**Author:** OJ Rocket
**Working name:** TBD
**Last updated:** August 11, 2026

## Table of Contents

1. [Overview](#1-overview)
2. [Base Platform Strategy](#2-base-platform-strategy)
3. [System Architecture](#3-system-architecture)
4. [Technology Stack](#4-technology-stack)
5. [Kernel](#5-kernel)
6. [Boot & Init](#6-boot-and-init)
7. [Storage & Filesystem](#7-storage-and-filesystem)
8. [Rollback & Update Architecture](#8-rollback-and-update-architecture)
9. [Package Management & Repositories](#9-package-management-and-repositories)
10. [Networking](#10-networking)
11. [Graphics Stack](#11-graphics-stack)
12. [Desktop Environment — Hyprland](#12-desktop-environment--hyprland)
13. [Desktop Applications & Services](#13-desktop-applications-and-services)
14. [Security](#14-security)
15. [Installer & First-Boot Experience](#15-installer-and-first-boot-experience)
16. [Custom Applications](#16-custom-applications)
17. [Performance Philosophy](#17-performance-philosophy)
18. [Developer Experience & Virtualization](#18-developer-experience-and-virtualization)
19. [Compatibility & Application Distribution](#19-compatibility-and-application-distribution)
20. [Hardware Support Matrix](#20-hardware-support-matrix)
21. [Build, CI/CD & Release Pipeline](#21-build-cicd-and-release-pipeline)
22. [Logging & Diagnostics](#22-logging-and-diagnostics)
23. [Branding & Design](#23-branding-and-design)
24. [Codebase Architecture](#24-codebase-architecture)
25. [Documentation Plan](#25-documentation-plan)
26. [Success Criteria](#26-success-criteria)
27. [Phased Delivery](#27-phased-delivery)
28. [Open Questions](#28-open-questions)

---

## 1. Overview

### 1.1 Vision

A modern, desktop-focused Linux distribution built around three reference points:

> Caelestia-level visual polish + Debian-level reliability + Fedora-level software freshness.

The distribution should feel cohesive and intentionally designed — not a collection of existing software wearing a new wallpaper.

### 1.2 Product Goals

1. Beautiful, highly polished desktop experience
2. Modern Wayland-first architecture
3. Fast software updates without sacrificing reliability
4. Strong rollback and recovery capabilities
5. Secure-by-default configuration
6. Excellent developer experience
7. Excellent hardware compatibility
8. Predictable system administration
9. Minimal unnecessary background services
10. Strong documentation and reproducible builds

### 1.3 Explicitly Deferred / Out of Scope for v1

- Rewriting the Linux kernel — the project consumes upstream, it doesn't replace it
- ARM64 support — x86_64 only initially
- Btrfs / XFS / ZFS as the default filesystem — ext4 is the default; other filesystems remain optional, non-default choices
- A custom Rust package-management frontend — DNF/RPM carries this initially; a custom frontend is a later possibility, and shouldn't duplicate DNF/RPM functionality when it arrives
- Large new C++ system components — C++ exists only because of the Qt/KDE ecosystem
- A fully independent (non-Fedora-derived) distro infrastructure — long-term direction, not a v1 requirement

---

## 2. Base Platform Strategy

**Base:** Fedora Linux, rather than an independent distribution built from scratch.

**Why Fedora:** modern kernel, recent Mesa, recent Linux userspace, strong hardware support, SELinux, the RPM ecosystem, DNF, existing infrastructure, a modern Wayland stack, and solid developer tooling.

**Differentiation surface** — where this project adds value on top of Fedora:
- Desktop experience
- Configuration
- Package repositories
- Update strategy
- Installer
- System utilities
- Branding
- Desktop integration
- Reliability mechanisms

**Long-term direction:** the project may eventually move toward more independent distribution infrastructure. Architecture decisions should avoid unnecessarily coupling custom components directly to Fedora internals, so that door stays open.

---

## 3. System Architecture

```
                         CUSTOM DISTRO
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
      Kernel               Userspace             Desktop
        │                     │                     │
      Linux              systemd/udev           Wayland
        │                     │                     │
      Drivers          Core GNU/Linux         Hyprland
        │                     │                     │
        │                Networking                │
        │                Security                  │
        │                Storage                   │
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                       Package System
                              │
                    Distribution Services
                              │
                 Installer / Update System
                              │
                           ISO
```

---

## 4. Technology Stack

| Language | Role | Notes |
|---|---|---|
| **Rust** | Primary language for new core system software: package-management components, update manager, update orchestration, rollback manager, system utilities, hardware detection, system info tools, daemons, desktop integration services, security-sensitive utilities, custom network utilities, CLI tools, system APIs, future graphical utilities | Chosen for memory safety, a strong type system, performance, concurrency, and modern tooling |
| **C** | Kernel interaction, low-level Linux APIs, native libraries, interoperability with existing Linux components | The project does not rewrite the kernel |
| **Assembly** | Boot-level functionality, architecture-specific low-level operations, CPU-specific optimizations, kernel/bootloader work if required | x86_64 initially; ARM64 planned later |
| **Bash** | Build scripts, installation scripts, bootstrap scripts, simple admin utilities, packaging helpers, dev workflows | Complex application logic belongs in Rust or Python instead |
| **Python** | Build automation, CI/CD utilities, testing infrastructure, repo tooling, release automation, ISO generation orchestration, dev tooling, data processing | Not the foundation of critical runtime components |
| **QML/Qt** | Custom launcher, settings app, control center, update UI, welcome app, hardware info UI, system utilities, first-run experience | Integrates naturally with KDE applications |
| **C++** | Present only because of the Qt/KDE ecosystem | Avoid new large C++ components without strong justification |

---

## 5. Kernel

Use the upstream Linux kernel with a controlled configuration rather than heavy downstream modification.

**Priorities:** hardware compatibility, desktop responsiveness, modern CPU scheduling, GPU support, NVMe, USB, Bluetooth, Wi-Fi, audio, suspend/resume, power management, virtualization, security.

**Configuration layout:**
```
kernel/
├── config/
│   ├── base
│   ├── desktop
│   ├── security
│   ├── networking
│   └── hardware
├── patches/
└── build/
```

Avoid carrying unnecessary downstream patches; prefer upstream functionality wherever possible.

---

## 6. Boot and Init

### 6.1 Boot stack

```
UEFI → Bootloader → Linux Kernel → initramfs → systemd → Userspace → Display Manager → Hyprland
```

### 6.2 Bootloader — open decision

Evaluate **systemd-boot**, **GRUB**, and **Limine**. Decide based on UEFI support, reliability, Secure Boot compatibility, kernel version management, and recovery options.

### 6.3 Init system

**systemd**, with required components: systemd, systemd-udev, systemd-logind, systemd-networkd (where appropriate), systemd-resolved or another carefully selected resolver, and systemd-boot if selected above. Services must stay minimal and clearly documented.

### 6.4 Initramfs — open decision

Must support root filesystem discovery, storage drivers, NVMe, USB storage, LUKS encryption, LVM (if supported), filesystem mounting, recovery mode, and kernel command-line configuration. Evaluate **dracut**, **mkinitcpio**, and a **systemd-based** initramfs; the choice should integrate cleanly with the Fedora-derived base.

---

## 7. Storage and Filesystem

**Default filesystem: ext4** — stable, mature, excellent Linux support, reliable recovery, good performance, simple administration.

**Indicative partition layout** (exact strategy still to be finalized):
```
EFI System Partition
        │
        ├── /boot/efi
        │
        └── Linux filesystem
                │
                ├── /
                ├── /home
                └── swap
```

**Storage support:** GPT, UEFI, ext4, LUKS2, swap, NVMe, SATA, USB storage. Full-disk encryption is an installer option, and security-sensitive storage operations require extensive testing before release.

**Optional, non-default filesystems for later consideration:** Btrfs, XFS, ZFS (where legally/technically appropriate).

---

## 8. Rollback and Update Architecture

This is the single highest-leverage open decision in this document — it shapes the installer, the update manager, the control center, and the package-management model in Section 9.

**Requirement:** recover cleanly from a failed package update, a broken graphics driver, a failed kernel update, a broken desktop configuration, or a boot failure.

**Candidate approaches (as originally scoped):**
- OSTree
- A deployment-based system architecture
- Package transaction rollback
- Bootable previous kernel/userspace
- Snapshot technology layered above ext4
- A separate immutable system partition architecture

### Recommendation

**OSTree / rpm-ostree** — the technology behind what Fedora now brands as **Fedora Atomic Desktops** (formerly Silverblue/Kinoite) — is worth prioritizing in evaluation, for a few concrete reasons:

- It doesn't require Btrfs. Atomicity comes from versioned, hardlinked deployments and bootloader entries, not filesystem snapshots — so it's compatible with the ext4 default from Section 7.
- Rollback becomes a single command (`rpm-ostree rollback`) instead of a bespoke rollback manager built from scratch.
- It's already proven in combination with this exact stack: the **Universal Blue** project (Bazzite, Bluefin) builds custom, branded atomic Fedora images via a Containerfile + CI pipeline, and community Hyprland spins of it already exist (e.g. hyprbazzite, hyprblue). "Fedora base + Hyprland + atomic rollback" is a pattern that already exists and can be studied or forked, not something that needs to be invented from zero.
- Adopting it would absorb most of the custom engineering work currently scoped for the rollback manager, a chunk of the installer, and a chunk of the update manager — freeing effort for the parts of this project that are actually differentiated: desktop experience, control center, branding.

**Trade-off to resolve explicitly:** this is a different overall model from the traditional DNF/RPM repository architecture described in Section 9 — image-based updates (the OS ships as a versioned image) versus package-repository updates (the OS is assembled from individually-versioned RPMs). It's a foundational choice, not an implementation detail, and should be made deliberately before Sections 9, 15, and 16 are built out.

**Status:** Recommended direction; final decision pending.

---

## 9. Package Management and Repositories

*Note: this section assumes the traditional RPM/DNF model. If the recommendation in Section 8 is adopted instead, this section will need to be revisited — image-based updates handle repository promotion differently.*

**Initial approach:** stay compatible with the Fedora/RPM ecosystem; use DNF/RPM directly. A custom Rust-based update/package frontend may be developed later, but should not unnecessarily duplicate DNF/RPM functionality.

**Conceptual flow:**
```
User → Custom Update Manager → Package Transaction Layer → DNF/RPM → Repository
```

**Repository channels:** Development → Testing → Stable

```
Development → Automated Build → Automated Tests → Testing → Integration Tests → Stable
```

- **Development:** newest packages, experimental features
- **Testing:** packages that passed automated build checks
- **Stable:** approved for general users

**Update categorization:**

| Category | Handling |
|---|---|
| Security | Highest priority |
| Critical bug fixes | Fast-tracked |
| Hardware compatibility | Fast-tracked when necessary |
| Normal packages | Full pipeline: automated testing → Testing → Stable |
| Major system updates | Longer testing period |

---

## 10. Networking

Networking is a first-class subsystem, with required support for Ethernet, Wi-Fi, Bluetooth, IPv4, IPv6, DHCP, DNS, VPN integration, network profiles, hotspots (where supported), and proxy configuration.

**Components to evaluate:** NetworkManager, systemd-networkd, iwd, wpa_supplicant, systemd-resolved.

**Desktop requirement:** Wi-Fi connection, Ethernet configuration, VPN setup, DNS configuration, and network troubleshooting must all be accessible graphically — no terminal required for ordinary use.

---

## 11. Graphics Stack

Wayland-first, with required components: Wayland, Mesa, Vulkan, OpenGL, DRM, GBM, PipeWire, libinput.

**GPU support:**
- **AMD** — Mesa + AMDGPU
- **Intel** — Mesa + Intel graphics stack
- **NVIDIA** — official driver support treated as a major compatibility requirement

**Required testing matrix:** Wayland + NVIDIA, hybrid graphics, laptop GPUs, external monitors, multiple monitors, suspend/resume, VRR (where supported).

---

## 12. Desktop Environment — Hyprland

**Primary desktop: Hyprland** — a Wayland compositor with tiling/window-management functionality, not a traditional standalone tiling window manager. The distribution should integrate Hyprland deeply rather than simply installing it.

**Default experience:** dynamic tiling, floating windows, workspaces, animations, blur, shadows (where appropriate), multi-monitor support, scratchpads, keybindings, window rules, gestures, screenshots, screen recording, clipboard integration, notification integration, idle handling, lock screen, power management.

**Configuration must be modular:**
```
~/.config/hypr/
├── hyprland.conf
├── keybindings.conf
├── monitors.conf
├── windows.conf
├── animations.conf
├── appearance.conf
└── environment.conf
```

---

## 13. Desktop Applications and Services

### 13.1 Default applications

| Role | Choice |
|---|---|
| File manager | Dolphin |
| Terminal | Kitty |
| Browser | TBD — Firefox vs. a Chromium-based browser |
| Text editor | TBD — lightweight graphical editor |
| System monitor | TBD — modern system monitor |
| Archive manager | TBD — graphical archive support |
| Screenshot utility | TBD — integrated tool |
| Screen recording | TBD — Wayland-compatible |
| Media apps | TBD — sensible audio/video defaults |

### 13.2 Core desktop services

Notifications, clipboard, screenshots, screen recording, Bluetooth, Wi-Fi, audio, brightness, battery, power profiles, night light, screen lock, idle management, wallpaper, Polkit authentication, secret storage.

### 13.3 Audio — PipeWire

Required: PulseAudio compatibility, ALSA, Bluetooth audio, microphone support, headphone support, USB audio, low-latency capability, graphical volume/device management.

### 13.4 Bluetooth

Support for Bluetooth audio, keyboards, mice, controllers, headsets, phones, and general Bluetooth devices, integrated into the control center.

---

## 14. Security

Security is designed in from the start, not layered on afterward.

**Required:** SELinux, Secure Boot support, UEFI, LUKS2, firewall, Polkit, user privilege separation, sandboxing, application permissions where possible, automatic security updates, signed packages, signed repositories.

**Potential components:** SELinux, firewalld, the audit subsystem, systemd security hardening.

---

## 15. Installer and First-Boot Experience

### 15.1 Installer

Must be usable by someone who has never installed Linux. Requirements: UEFI support, automatic partitioning, manual partitioning, ext4, encryption, user creation, timezone, keyboard, language, network setup, bootloader configuration, optional disk wipe, dual-boot handling, installation progress, and error reporting.

*If Section 8's recommendation is adopted, an existing installer (Fedora's own, or tooling from the Universal Blue ecosystem) may cover most of this rather than building one from scratch.*

### 15.2 First-boot experience

```
Boot → Welcome Screen → Network / Updates / Drivers / Appearance / Privacy / Default apps / Keyboard shortcuts
```

By the end of first boot, the user should understand: how to open applications, how Hyprland works, workspace controls, keyboard shortcuts, how to access settings, how to update, and how to recover the system.

---

## 16. Custom Applications

### 16.1 Control Center

Sections: Appearance, Display, Network, Bluetooth, Audio, Keyboard, Mouse & Touchpad, Power, Applications, Privacy, Security, Users, Storage, Updates, System.

### 16.2 Update Manager

**GUI features:** check for updates, view packages, security update indicators, update history, restart requirement, kernel updates, rollback/recovery, repository status, update errors, background update notifications.

**CLI (command names TBD):**
```
distro update
distro upgrade
distro rollback
distro history
distro system-info
distro doctor
```

### 16.3 System Diagnostics ("distro doctor")

Inspects kernel, GPU, drivers, network, audio, disk, filesystem, bootloader, services, package database, desktop session, Wayland, Hyprland, and logs. Example output:

```
System Health
────────────────────
Kernel       ✓
Graphics     ✓
Wayland      ✓
Hyprland     ✓
Audio        ✓
Network      ✓
Storage      ✓
Packages     ✓
Security     ✓
```

---

## 17. Performance Philosophy

Optimize for fast boot, low idle CPU usage, low memory overhead, fast application launch, smooth animations, low input latency, efficient background services, and good battery life. Do not chase benchmark numbers at the expense of reliability.

---

## 18. Developer Experience and Virtualization

**Toolchain to provide out of the box:** GCC, Clang, LLVM, Rust, Python, Git, CMake, Make, pkg-config, Docker/Podman, QEMU, GDB, strace, perf. A developer should be able to install the distro and start working immediately.

**Virtualization support:** QEMU/KVM, libvirt, containers, Podman, Docker compatibility. The distro itself should be easy to test inside QEMU, VirtualBox, and VMware.

---

## 19. Compatibility and Application Distribution

**Gaming is treated as an important desktop use case**, with required compatibility for Steam, Proton, Wine, Flatpak, AppImage, containers, virtual machines, and common developer tools.

**Application distribution strategy:**

| Format | Use case |
|---|---|
| Native packages | System components, libraries, core applications |
| Flatpak | Desktop applications, third-party software, sandboxed applications |
| Containers | Development / server workloads |

The distribution should avoid forcing every graphical application into the native package repository.

---

## 20. Hardware Support Matrix

| | Initial | Future |
|---|---|---|
| CPU | x86_64 | ARM64 |
| GPU | AMD, Intel, NVIDIA | — |
| Devices | Desktop, laptop, gaming PC, workstation | ARM64 laptops/desktops, embedded devices |

---

## 21. Build, CI/CD and Release Pipeline

### 21.1 ISO build system

Requirements: automated ISO builds, versioning, checksums, GPG/signature verification, reproducibility, CI testing, QEMU boot testing.

```
Git Commit → Build Packages → Build Root Filesystem → Build ISO
   → Boot ISO in QEMU → Automated Tests → Sign ISO → Release
```

### 21.2 CI/CD test matrix

| Stage | Checks |
|---|---|
| Build | Packages compile, dependencies resolve, ISO builds |
| Boot | ISO boots, installer launches, installed system boots |
| Desktop | Wayland launches, Hyprland launches, Dolphin launches, Kitty launches, audio works, network works |
| Update | Package updates, kernel updates, recovery |
| Regression | Existing functionality remains operational |

---

## 22. Logging and Diagnostics

Use the systemd journal where appropriate. Provide tooling to collect system logs, kernel logs, hardware information, package information, crash information, graphics information, and network information into an exportable diagnostic report — without exposing sensitive information by default.

---

## 23. Branding and Design

### 23.1 Identity elements to define

Name, logo, mascot, color system, typography, iconography, wallpapers, boot animation, login screen, installer appearance, application styling, documentation style — consistent across the entire OS.

### 23.2 Design philosophy

**Should feel:** modern, minimal, fast, premium, technical without being intimidating, consistent, responsive.

**Avoid:** excessive animations, unnecessary background services, bloated applications, duplicated utilities, inconsistent theming, random third-party customization.

---

## 24. Codebase Architecture

```
distro/
│
├── kernel/
├── packages/
├── repositories/
├── iso/
├── installer/
├── desktop/
│   ├── hyprland/
│   ├── launcher/
│   ├── control-center/
│   ├── notifications/
│   └── update-manager/
│
├── system/
│   ├── networking/
│   ├── audio/
│   ├── power/
│   ├── security/
│   └── storage/
│
├── tools/
├── build/
├── tests/
├── documentation/
└── artwork/
```

---

## 25. Documentation Plan

| Audience | Covers |
|---|---|
| Users | Installation, desktop, updates, troubleshooting, recovery |
| Developers | Building the distro, building packages, repository architecture, CI, contributing, writing system components |
| Maintainers | Release process, security updates, package policies, kernel update/versioning policy |

---

## 26. Success Criteria

No numeric targets are set yet — that's worth defining once Section 27's phase-1 scope is locked in. Directionally, v1 is on track if a running system demonstrably satisfies the ten goals in Section 1.2: it looks and feels polished, it's Wayland-first end to end, updates land quickly without breaking the system, a bad update or driver can be recovered from without a reinstall, defaults are secure, a developer is productive immediately after install, common hardware works out of the box, administration is predictable, background services stay minimal, and the build is documented and reproducible.

---

## 27. Phased Delivery

The source material already draws a line between what's needed initially and what's explicitly future work. Making that explicit:

**Phase 1 (initial release):**
- x86_64 only
- ext4 default filesystem
- Fedora base via DNF/RPM (or the atomic model from Section 8, if that direction is chosen)
- Hyprland desktop, deeply configured
- Core desktop services and default applications
- A working installer and first-boot flow
- Baseline security posture (SELinux, LUKS2, Secure Boot, firewall)
- CI/CD and ISO build pipeline

**Later phases:**
- ARM64 hardware support
- Btrfs / XFS / ZFS as selectable, non-default filesystems
- A custom Rust package/update frontend, if DNF/RPM (or rpm-ostree) alone isn't enough
- Movement toward more independent distribution infrastructure, decoupled from Fedora internals

---

## 28. Open Questions

- Working name and branding identity
- Bootloader: systemd-boot vs. GRUB vs. Limine
- Initramfs tooling: dracut vs. mkinitcpio vs. systemd-based
- **Rollback/update architecture** — see Section 8's recommendation; final call still pending
- Default browser: Firefox vs. a Chromium-based browser
- Default text editor, system monitor, archive manager, and media applications
- Exact partition layout and defaults
- Networking stack: NetworkManager vs. systemd-networkd vs. iwd/wpa_supplicant, and resolver choice
