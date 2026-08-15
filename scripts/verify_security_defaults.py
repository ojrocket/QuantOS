#!/usr/bin/env python3
"""Validate that the QuantOS project enforces the required security baseline."""

from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent

REQUIRED_FILES = [
    ROOT / "README.md",
    ROOT / "custom-linux-distro-prd.md",
    ROOT / "docs" / "architecture.md",
    ROOT / "docs" / "security-hardening.md",
    ROOT / "distro" / "system" / "security" / "security-baseline.md",
]

REQUIRED_DIRS = [
    ROOT / "distro",
    ROOT / "distro" / "system",
    ROOT / "distro" / "system" / "security",
    ROOT / "distro" / "desktop",
    ROOT / "distro" / "build",
    ROOT / "scripts",
]

BAD_PATTERNS = [
    "".join(["NO", "PASSWD"]),
    "PasswordAuthentication" + "=yes",
    "PermitRootLogin" + "=yes",
    "world" + "-writable",
    "allow" + " all",
    "sudoers ALL=(ALL) " + "".join(["NO", "PASSWD"]) + ": ALL",
]


def check_required_files() -> list[str]:
    missing = []
    for path in REQUIRED_FILES:
        if not path.exists():
            missing.append(f"Missing required file: {path.relative_to(ROOT)}")
    return missing


def check_required_dirs() -> list[str]:
    missing = []
    for directory in REQUIRED_DIRS:
        if not directory.exists():
            missing.append(f"Missing required directory: {directory.relative_to(ROOT)}")
    return missing


def scan_for_bad_patterns() -> list[str]:
    hits: list[str] = []
    text_files = [
        p for p in ROOT.rglob("*")
        if p.is_file() and p.suffix.lower() in {".md", ".txt", ".conf", ".ini", ".yaml", ".yml", ".py", ".sh"}
    ]

    for path in text_files:
        try:
            content = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        for pattern in BAD_PATTERNS:
            if pattern in content:
                hits.append(f"Disallowed pattern '{pattern}' found in {path.relative_to(ROOT)}")
    return hits


def main() -> int:
    errors: list[str] = []
    errors.extend(check_required_files())
    errors.extend(check_required_dirs())
    errors.extend(scan_for_bad_patterns())

    if errors:
        print("QuantOS security baseline validation failed.")
        for error in errors:
            print(f"- {error}")
        return 1

    print("QuantOS security baseline validation passed.")
    print("No insecure default patterns detected in the repository structure.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
