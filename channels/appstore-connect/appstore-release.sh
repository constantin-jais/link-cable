#!/usr/bin/env bash
set -euo pipefail

# Gear Cable stable adapter for rorkai/App-Store-Connect-CLI (`asc`).
# Product CI must call this wrapper, not upstream `asc` commands directly.

ROOT_DIR="${ASC_WORKSPACE_DIR:-$(pwd)}"
CONFIG_PATH="${ASC_RELEASE_CONFIG:-appstore/release.config.json}"
CLI_BIN="${ASC_CLI_BIN:-asc}"
DRY_RUN="${ASC_DRY_RUN:-0}"
AUTH_NAME="${ASC_AUTH_NAME:-RumbleCI}"
TMP_KEY_FILE=""
AUTH_DONE="0"

# Privacy default: upstream telemetry is useful for maintainers but disabled in CI
# unless explicitly re-enabled by the caller.
export ASC_TELEMETRY_DISABLED="${ASC_TELEMETRY_DISABLED:-1}"

usage() {
  cat <<'USAGE'
Usage:
  appstore-release.sh validate
  appstore-release.sh auth
  appstore-release.sh upload-build [--ipa <path>]
  appstore-release.sh upload-metadata
  appstore-release.sh upload-screenshots
  appstore-release.sh submit-review [--ipa <path>]
  appstore-release.sh status
  appstore-release.sh compat

Required env for publication actions:
  ASC_KEY_ID                  App Store Connect API key id.
  ASC_ISSUER_ID               App Store Connect issuer id.
  ASC_PRIVATE_KEY             App Store Connect .p8 private key content.
  ASC_TEAM_ID                 Apple team id.

Optional env:
  ASC_CLI_BIN                 Path/name of pinned asc executable. Default: asc.
  ASC_RELEASE_CONFIG          Release config path. Default: appstore/release.config.json.
  ASC_DRY_RUN=1               Print commands without executing publication actions.
  ASC_TELEMETRY_DISABLED=0    Re-enable upstream telemetry if intentionally desired.

Command mapping env overrides:
  ASC_CMD_AUTH
  ASC_CMD_UPLOAD_BUILD
  ASC_CMD_UPLOAD_METADATA
  ASC_CMD_UPLOAD_SCREENSHOTS
  ASC_CMD_SUBMIT_REVIEW
  ASC_CMD_STATUS
  ASC_CMD_COMPAT

Template variables expanded by the wrapper:
  {APP_ID} {BUNDLE_ID} {APP_NAME} {VERSION} {IPA} {METADATA} {SCREENSHOTS}
  {CONFIG} {KEY_ID} {ISSUER_ID} {KEY_FILE} {TEAM_ID} {AUTH_NAME}
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

require_file() { [[ -f "$1" ]] || fail "missing file: $1"; }
require_dir() { [[ -d "$1" ]] || fail "missing directory: $1"; }
require_env() { local name="$1"; [[ -n "${!name:-}" ]] || fail "missing env: $name"; }

json_get() {
  local expr="$1"
  python3 - "$ROOT_DIR/$CONFIG_PATH" "$expr" <<'PY'
import json, sys
path, expr = sys.argv[1], sys.argv[2]
try:
    with open(path, 'r', encoding='utf-8') as fh:
        cur = json.load(fh)
    for part in expr.split('.'):
        cur = cur[part]
    if cur is None:
        print("")
    else:
        print(cur)
except (KeyError, TypeError):
    print("")
PY
}

cfg() {
  local expr="$1"
  local fallback="${2:-}"
  local value
  value="$(json_get "$expr")"
  if [[ -n "$value" ]]; then
    printf '%s' "$value"
  else
    printf '%s' "$fallback"
  fi
}

prepare_key_file() {
  [[ -n "$TMP_KEY_FILE" ]] && return 0
  require_env ASC_PRIVATE_KEY
  TMP_KEY_FILE="$(mktemp "${TMPDIR:-/tmp}/asc-key.XXXXXX")"
  chmod 600 "$TMP_KEY_FILE"
  printf '%s\n' "$ASC_PRIVATE_KEY" > "$TMP_KEY_FILE"
}

validate_config() {
  require_file "$ROOT_DIR/$CONFIG_PATH"
  command -v "$CLI_BIN" >/dev/null 2>&1 || fail "ASC_CLI_BIN not executable/found: $CLI_BIN"

  local contract_version
  contract_version="$(cfg version)"
  [[ "$contract_version" == "app-store-release.v0.1" ]] || fail "unsupported release config version: $contract_version"

  [[ -n "$(cfg app.name)" ]] || fail "app.name is empty"
  [[ -n "$(cfg app.bundle_id)" ]] || fail "app.bundle_id is empty"
  [[ -n "$(cfg app.app_store_id)" ]] || fail "app.app_store_id is empty"
  [[ -n "$(cfg app.primary_locale)" ]] || fail "app.primary_locale is empty"
  [[ -n "$(cfg release.ipa_path)" ]] || fail "release.ipa_path is empty"
  [[ -n "$(cfg release.version "${CI_COMMIT_TAG#ios-v}")" ]] || fail "release.version is empty and cannot be inferred from ios-v* tag"

  require_dir "$ROOT_DIR/$(cfg release.metadata_path appstore/metadata)"
  require_dir "$ROOT_DIR/$(cfg release.screenshots_path appstore/screenshots)"
}

validate_secrets() {
  require_env ASC_KEY_ID
  require_env ASC_ISSUER_ID
  require_env ASC_TEAM_ID
  prepare_key_file
}

expand_template() {
  local template="$1"
  local ipa="${2:-$ROOT_DIR/$(cfg release.ipa_path)}"
  local version
  version="$(cfg release.version "${CI_COMMIT_TAG#ios-v}")"

  template="${template//\{APP_ID\}/$(cfg app.app_store_id)}"
  template="${template//\{BUNDLE_ID\}/$(cfg app.bundle_id)}"
  template="${template//\{APP_NAME\}/$(cfg app.name)}"
  template="${template//\{VERSION\}/$version}"
  template="${template//\{IPA\}/$ipa}"
  template="${template//\{METADATA\}/$ROOT_DIR/$(cfg release.metadata_path appstore/metadata)}"
  template="${template//\{SCREENSHOTS\}/$ROOT_DIR/$(cfg release.screenshots_path appstore/screenshots)}"
  template="${template//\{CONFIG\}/$ROOT_DIR/$CONFIG_PATH}"
  template="${template//\{KEY_ID\}/${ASC_KEY_ID:-}}"
  template="${template//\{ISSUER_ID\}/${ASC_ISSUER_ID:-}}"
  template="${template//\{KEY_FILE\}/$TMP_KEY_FILE}"
  template="${template//\{TEAM_ID\}/${ASC_TEAM_ID:-}}"
  template="${template//\{AUTH_NAME\}/$AUTH_NAME}"
  printf '%s' "$template"
}

default_mapping() {
  case "$1" in
    ASC_CMD_AUTH) printf '%s' 'auth login --bypass-keychain --name {AUTH_NAME} --key-id {KEY_ID} --issuer-id {ISSUER_ID} --private-key {KEY_FILE}' ;;
    ASC_CMD_UPLOAD_BUILD) printf '%s' 'builds upload --app {APP_ID} --ipa {IPA} --wait --output json' ;;
    ASC_CMD_UPLOAD_METADATA) printf '%s' 'metadata apply --app {APP_ID} --version {VERSION} --dir {METADATA}' ;;
    ASC_CMD_UPLOAD_SCREENSHOTS) printf '%s' 'screenshots apply --app {APP_ID} --version {VERSION} --review-output-dir {SCREENSHOTS} --confirm' ;;
    ASC_CMD_SUBMIT_REVIEW) printf '%s' 'publish appstore --app {APP_ID} --ipa {IPA} --version {VERSION} --submit --confirm' ;;
    ASC_CMD_STATUS) printf '%s' 'status --app {APP_ID} --output json' ;;
    ASC_CMD_COMPAT) printf '%s' 'version' ;;
    *) return 1 ;;
  esac
}

run_template() {
  local env_name="$1"
  local ipa="${2:-}"
  local template="${!env_name:-}"
  if [[ -z "$template" ]]; then
    template="$(default_mapping "$env_name")"
  fi

  local expanded
  expanded="$(expand_template "$template" "$ipa")"
  log "$CLI_BIN $expanded"
  if [[ "$DRY_RUN" == "1" ]]; then
    return 0
  fi

  # Mapping strings are controlled by Gear Cable/CI, not user input.
  # shellcheck disable=SC2206
  local args=( $expanded )
  "$CLI_BIN" "${args[@]}"
}

authenticate() {
  validate_config
  validate_secrets
  [[ "$AUTH_DONE" == "1" ]] && return 0
  run_template ASC_CMD_AUTH
  AUTH_DONE="1"
}

ACTION="${1:-}"
[[ -n "$ACTION" ]] || { usage; exit 2; }
shift || true

case "$ACTION" in
  validate)
    validate_config
    validate_secrets
    log "validated $CONFIG_PATH for $(cfg app.name) using $($CLI_BIN version 2>/dev/null || true)"
    ;;
  auth)
    authenticate
    ;;
  upload-build)
    validate_config
    IPA=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --ipa) IPA="${2:-}"; shift 2 ;;
        *) fail "unknown argument for upload-build: $1" ;;
      esac
    done
    [[ -n "$IPA" ]] || IPA="$ROOT_DIR/$(cfg release.ipa_path)"
    require_file "$IPA"
    authenticate
    run_template ASC_CMD_UPLOAD_BUILD "$IPA"
    ;;
  upload-metadata)
    authenticate
    run_template ASC_CMD_UPLOAD_METADATA
    ;;
  upload-screenshots)
    authenticate
    run_template ASC_CMD_UPLOAD_SCREENSHOTS
    ;;
  submit-review)
    validate_config
    IPA=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --ipa) IPA="${2:-}"; shift 2 ;;
        *) fail "unknown argument for submit-review: $1" ;;
      esac
    done
    [[ -n "$IPA" ]] || IPA="$ROOT_DIR/$(cfg release.ipa_path)"
    require_file "$IPA"
    authenticate
    run_template ASC_CMD_SUBMIT_REVIEW "$IPA"
    ;;
  status)
    authenticate
    run_template ASC_CMD_STATUS
    ;;
  compat)
    command -v "$CLI_BIN" >/dev/null 2>&1 || fail "ASC_CLI_BIN not executable/found: $CLI_BIN"
    COMPAT_ARGS="${ASC_CMD_COMPAT:-$(default_mapping ASC_CMD_COMPAT)}"
    log "$CLI_BIN $COMPAT_ARGS"
    if [[ "$DRY_RUN" != "1" ]]; then
      # shellcheck disable=SC2206
      COMPAT_ARGV=( $COMPAT_ARGS )
      "$CLI_BIN" "${COMPAT_ARGV[@]}"
      "$CLI_BIN" --help >/dev/null 2>&1 || fail "asc --help failed"
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
