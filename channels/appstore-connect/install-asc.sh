#!/usr/bin/env bash
set -euo pipefail

# Installs pinned rorkai/App-Store-Connect-CLI (`asc`) release binary.
# Default pin is recorded in compatibility.yml and mirrored here for CI ergonomics.

VERSION="${ASC_VERSION:-2.5.0}"
INSTALL_DIR="${ASC_INSTALL_DIR:-.gear-cable/bin}"
REPO="https://github.com/rorkai/App-Store-Connect-CLI"

os="$(uname -s)"
arch="$(uname -m)"
case "$os" in
  Darwin) platform="macOS" ;;
  Linux) platform="linux" ;;
  *) echo "unsupported OS: $os" >&2; exit 1 ;;
esac
case "$arch" in
  x86_64|amd64) cpu="amd64" ;;
  arm64|aarch64) cpu="arm64" ;;
  *) echo "unsupported arch: $arch" >&2; exit 1 ;;
esac

asset="asc_${VERSION}_${platform}_${cpu}"
url="$REPO/releases/download/${VERSION}/${asset}"
checksums_url="$REPO/releases/download/${VERSION}/asc_${VERSION}_checksums.txt"

mkdir -p "$INSTALL_DIR"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/asc-install.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$url" -o "$tmp/$asset"
curl -fsSL "$checksums_url" -o "$tmp/checksums.txt"

if command -v sha256sum >/dev/null 2>&1; then
  (cd "$tmp" && grep "  $asset$" checksums.txt | sha256sum -c -) >&2
elif command -v shasum >/dev/null 2>&1; then
  expected="$(grep "  $asset$" "$tmp/checksums.txt" | awk '{print $1}')"
  actual="$(shasum -a 256 "$tmp/$asset" | awk '{print $1}')"
  [[ "$expected" == "$actual" ]] || { echo "checksum mismatch for $asset" >&2; exit 1; }
else
  echo "missing sha256sum/shasum for checksum verification" >&2
  exit 1
fi

install -m 0755 "$tmp/$asset" "$INSTALL_DIR/asc"
printf '%s\n' "$INSTALL_DIR/asc"
