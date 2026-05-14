#!/usr/bin/env bash
set -euo pipefail

cargo deny check
cargo audit
