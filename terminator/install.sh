#!/usr/bin/env bash
# Purpose: install the tracked Terminator configuration.
# Inputs: the config file beside this script.
# Outputs: XDG_CONFIG_HOME/terminator/config (defaults to ~/.config/terminator/config).
# Prerequisites: Bash and standard Unix tools.
# Usage: ./install.sh [--dry-run]
# Parameters: XDG_CONFIG_HOME changes the base target directory.
# File effects: creates or replaces config, records rollback state, and creates a backup.

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_FILE="${SCRIPT_DIR}/config"
readonly TARGET_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/terminator"
readonly TARGET_FILE="${TARGET_DIR}/config"
readonly STATE_DIR="${TARGET_DIR}/.dotfiles-terminator-state"
readonly PREVIOUS_FILE="${STATE_DIR}/config.previous"
readonly ABSENT_FILE="${STATE_DIR}/config.was_absent"
readonly TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

dry_run=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run]

Install the tracked Terminator configuration. The target defaults to
~/.config/terminator/config.

Options:
  --dry-run  Show what would change without modifying files.
  -h, --help Show this help text.
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

case "${1:-}" in
  "") ;;
  --dry-run) dry_run=true ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    fail "unknown argument: $1"
    ;;
esac

if (( $# > 1 )); then
  usage >&2
  fail "expected at most one argument"
fi

[[ "${TARGET_DIR}" == /* ]] || fail "target directory must be an absolute path: ${TARGET_DIR}"
[[ -f "${SOURCE_FILE}" ]] || fail "missing source file: ${SOURCE_FILE}"
[[ ! -L "${TARGET_FILE}" ]] || fail "refusing to replace symbolic link: ${TARGET_FILE}"
[[ ! -e "${TARGET_FILE}" || -f "${TARGET_FILE}" ]] || fail "target is not a regular file: ${TARGET_FILE}"

if [[ -f "${TARGET_FILE}" ]] && cmp -s -- "${SOURCE_FILE}" "${TARGET_FILE}"; then
  printf 'Unchanged: %s\n' "${TARGET_FILE}"
  exit 0
fi

if [[ "${dry_run}" == true ]]; then
  printf 'Would install: %s\n' "${TARGET_FILE}"
  exit 0
fi

mkdir -p -- "${TARGET_DIR}" "${STATE_DIR}"
chmod 700 -- "${STATE_DIR}"

if [[ ! -e "${PREVIOUS_FILE}" && ! -e "${ABSENT_FILE}" ]]; then
  if [[ -f "${TARGET_FILE}" ]]; then
    cp -p -- "${TARGET_FILE}" "${PREVIOUS_FILE}"
    chmod 600 -- "${PREVIOUS_FILE}"
  else
    : > "${ABSENT_FILE}"
    chmod 600 -- "${ABSENT_FILE}"
  fi
fi

if [[ -f "${TARGET_FILE}" ]]; then
  backup_file="${TARGET_FILE}.backup.${TIMESTAMP}"
  if [[ -e "${backup_file}" ]]; then
    backup_file="${backup_file}.$$"
  fi
  cp -p -- "${TARGET_FILE}" "${backup_file}"
  printf 'Backed up %s to %s\n' "${TARGET_FILE}" "${backup_file}"
fi

cp -- "${SOURCE_FILE}" "${TARGET_FILE}"
printf 'Installed: %s\n' "${TARGET_FILE}"
printf 'Terminator configuration installation complete. Restart Terminator to use it.\n'
