#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
fi

if [[ "${ID:-}" != "fedora" ]]; then
  echo "QuantOS ISO builds are intended for Fedora-based hosts only." >&2
  echo "Detected OS: ${PRETTY_NAME:-unknown}" >&2
  exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
  echo "dnf is required to install the Fedora live-image tooling." >&2
  exit 2
fi

sudo dnf install -y lorax livemedia-creator pykickstart rsync genisoimage

echo "Fedora build tooling installed. You can now run:"
echo "  sudo bash build/build-iso.sh --output-dir ./output --arch x86_64"
