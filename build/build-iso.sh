#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME=$(basename "$0")
PROJECT_NAME="QuantOS"
OUTPUT_DIR="${OUTPUT_DIR:-$PWD/output}"
ARCH="${ARCH:-x86_64}"
KS_PATH="${KS_PATH:-$PWD/build/quantos.ks}"
WORK_DIR="${WORK_DIR:-$PWD/.build-tmp}"
DRY_RUN=0

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [options]

Build a Fedora-based QuantOS ISO from a Kickstart definition.

Options:
  --output-dir DIR     Directory for generated artifacts (default: ./output)
  --arch ARCH          Target architecture (default: x86_64)
  --kickstart PATH     Path to the Kickstart file (default: ./build/quantos.ks)
  --work-dir DIR       Temporary work directory (default: ./.build-tmp)
  --dry-run            Print commands without running them
  -h, --help           Show this help

Requirements:
  - Fedora-based build host
  - livemedia-creator or lorax installed
  - root privileges when the ISO is generated
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --arch)
      ARCH="$2"
      shift 2
      ;;
    --kickstart)
      KS_PATH="$2"
      shift 2
      ;;
    --work-dir)
      WORK_DIR="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$KS_PATH" ]]; then
  echo "Kickstart file not found: $KS_PATH" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$WORK_DIR"

if [[ "$ARCH" != "x86_64" ]]; then
  echo "Unsupported architecture: $ARCH" >&2
  echo "QuantOS v1 targets x86_64 only." >&2
  exit 1
fi

CMD=(livemedia-creator \
  --ks "$KS_PATH" \
  --resultdir "$OUTPUT_DIR" \
  --project "$PROJECT_NAME" \
  --make-iso \
  --iso-name "quantos-${ARCH}.iso" \
  --title "$PROJECT_NAME" \
  --releasever 40 \
  --tmpdir "$WORK_DIR")

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] ${CMD[*]}"
  exit 0
fi

if ! command -v livemedia-creator >/dev/null 2>&1; then
  echo "livemedia-creator is not installed on this host." >&2
  echo "Install the Fedora Live Media tools and re-run this script." >&2
  exit 2
fi

if [[ $EUID -ne 0 ]]; then
  echo "This build script requires root privileges to generate the ISO." >&2
  echo "Re-run with sudo or as root." >&2
  exit 3
fi

echo "Building ${PROJECT_NAME} ISO for ${ARCH}..."
"${CMD[@]}"

echo "ISO generated at: $OUTPUT_DIR/quantos-${ARCH}.iso"
