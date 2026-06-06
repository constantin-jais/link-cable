#!/usr/bin/env bash
set -euo pipefail

# Stable internal adapter for rorkai/App-Store-Connect-CLI.
# Product CI must call this wrapper, not the upstream CLI directly.

ROOT_DIR="${ASC_WORKSPACE_DIR:-$(pwd)}"
CONFIG_PATH="${ASC_RELEASE_CONFIG:-appstore/release.config.json}"
CLI_BIN="${ASC_CLI_BIN:-}"
DRY_RUN="${ASC_DRY_RUN:-0}"
TMP_KEY_FILE=""

usage() {
  cat <<'USAGE'
Usage:
  appstore-release.sh validate
  appstore-release.sh upload-build --ipa <path>
  appstore-release.sh upload-metadata
  appstore-release.sh submit-review
  appstore-release.sh status
  appstore-release.sh compat

Required env:
  ASC_CLI_BIN                 Path/name of pinned App-Store-Connect-CLI executable.
  ASC_KEY_ID                  App Store Connect API key id.
  ASC_ISSUER_ID               App Store Connect issuer id.
  ASC_PRIVATE_KEY             App Store Connect .p8 private key content.
  ASC_TEAM_ID                 Apple team id.

Action command mappings:
  ASC_CMD_UPLOAD_BUILD        Upstream CLI args template for upload-build.
  ASC_CMD_UPLOAD_METADATA     Upstream CLI args template for upload-metadata.
  ASC_CMD_SUBMIT_REVIEW       Upstream CLI args template for submit-review.
  ASC_CMD_STATUS              Upstream CLI args template for status.
  ASC_CMD_COMPAT              Upstream CLI args template for compatibility check.

Template variables expanded by the wrapper:
  {IPA} {CONFIG} {KEY_ID} {ISSUER_ID} {KEY_FILE} {TEAM_ID}

Example:
  ASC_CMD_UPLOAD_BUILD='upload-build --ipa {IPA} --key-id {KEY_ID} --issuer-id {ISSUER_ID} --private-key {KEY_FILE}' \
    appstore-release.sh upload-build --ipa dist/app.ipa
USAGE
}

log() { printf '[appstore-release] %s\n' "$*" >&2; }
fail() { log "ERROR: $*"; exit 1; }

cleanup() {
  if [[ -n "$TMP_KEY_FILE" && -f "$TMP_KEY_FILE" ]]; then
    rm -f "$TMP_KEY_FILE"
  fi
}
trap cleanup EXIT

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "missing file: $path"
}

require_dir() {
  local path="$1"
  [[ -d "$path" ]] || fail "missing directory: $path"
}

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || fail "missing env: $name"
}

json_get() {
  local expr="$1"
  python3 - "$ROOT_DIR/$CONFIG_PATH" "$expr" <<'PY'
import json, sys
path, expr = sys.argv[1], sys.argv[2]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
cur = data
for part in expr.split('.'):
    cur = cur[part]
print(cur)
PY
}

prepare_key_file() {
  [[ -n "$TMP_KEY_FILE" ]] && return 0
  require_env ASC_PRIVATE_KEY
  TMP_KEY_FILE="$(mktemp "${TMPDIR:-/tmp}/asc-key.XXXXXX.p8")"
  chmod 600 "$TMP_KEY_FILE"
  printf '%s\n' "$ASC_PRIVATE_KEY" > "$TMP_KEY_FILE"
}

validate_common() {
  require_file "$ROOT_DIR/$CONFIG_PATH"
  require_env ASC_CLI_BIN
  command -v "$CLI_BIN" >/dev/null 2>&1 || fail "ASC_CLI_BIN not executable/found: $CLI_BIN"

  local version
  version="$(json_get version)"
  [[ "$version" == "app-store-release.v0.1" ]] || fail "unsupported release config version: $version"

  require_env ASC_KEY_ID
  require_env ASC_ISSUER_ID
  require_env ASC_TEAM_ID
  prepare_key_file

  local ipa_path metadata_path screenshots_path
  ipa_path="$(json_get release.ipa_path)"
  metadata_path="$(json_get release.metadata_path)"
  screenshots_path="$(json_get release.screenshots_path)"

  [[ -n "$ipa_path" ]] || fail "release.ipa_path is empty"
  require_dir "$ROOT_DIR/$metadata_path"
  require_dir "$ROOT_DIR/$screenshots_path"
}

expand_template() {
  local template="$1"
  local ipa="${2:-}"
  template="${template//\{IPA\}/$ipa}"
  template="${template//\{CONFIG\}/$ROOT_DIR/$CONFIG_PATH}"
  template="${template//\{KEY_ID\}/${ASC_KEY_ID:-}}"
  template="${template//\{ISSUER_ID\}/${ASC_ISSUER_ID:-}}"
  template="${template//\{KEY_FILE\}/$TMP_KEY_FILE}"
  template="${template//\{TEAM_ID\}/${ASC_TEAM_ID:-}}"
  printf '%s' "$template"
}

run_mapped() {
  local env_name="$1"
  local ipa="${2:-}"
  local template="${!env_name:-}"
  [[ -n "$template" ]] || fail "missing action command mapping env: $env_name"

  local expanded
  expanded="$(expand_template "$template" "$ipa")"
  log "$CLI_BIN $expanded"
  if [[ "$DRY_RUN" == "1" ]]; then
    return 0
  fi

  # shellcheck disable=SC2206
  local args=( $expanded )
  "$CLI_BIN" "${args[@]}"
}

ACTION="${1:-}"
[[ -n "$ACTION" ]] || { usage; exit 2; }
shift || true

case "$ACTION" in
  validate)
    validate_common
    log "validated $CONFIG_PATH for $(json_get app.name)"
    ;;
  upload-build)
    validate_common
    IPA=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --ipa) IPA="${2:-}"; shift 2 ;;
        *) fail "unknown argument for upload-build: $1" ;;
      esac
    done
    [[ -n "$IPA" ]] || IPA="$ROOT_DIR/$(json_get release.ipa_path)"
    require_file "$IPA"
    run_mapped ASC_CMD_UPLOAD_BUILD "$IPA"
    ;;
  upload-metadata)
    validate_common
    run_mapped ASC_CMD_UPLOAD_METADATA
    ;;
  submit-review)
    validate_common
    run_mapped ASC_CMD_SUBMIT_REVIEW
    ;;
  status)
    validate_common
    run_mapped ASC_CMD_STATUS
    ;;
  compat)
    require_env ASC_CLI_BIN
    command -v "$CLI_BIN" >/dev/null 2>&1 || fail "ASC_CLI_BIN not executable/found: $CLI_BIN"
    if [[ -n "${ASC_CMD_COMPAT:-}" ]]; then
      run_mapped ASC_CMD_COMPAT
    else
      log "$CLI_BIN --help"
      [[ "$DRY_RUN" == "1" ]] || "$CLI_BIN" --help >/dev/null
    fi
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage
    fail "unknown action: $ACTION"
    ;;
esac
