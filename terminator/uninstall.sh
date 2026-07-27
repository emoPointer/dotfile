#!/usr/bin/env bash
# Purpose: undo changes previously made by terminator/install.sh.
# Inputs: rollback state in the Terminator configuration directory.
# Outputs: the restored or removed Terminator config file.
# Prerequisites: Bash and standard Unix tools.
# Usage: ./uninstall.sh [--dry-run]
# Parameters: XDG_CONFIG_HOME must match the value used during installation.
# File effects: restores or removes config, creates a safety backup, and removes rollback state.

set -euo pipefail

readonly TARGET_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/terminator"
readonly TARGET_FILE="${TARGET_DIR}/config"
readonly STATE_DIR="${TARGET_DIR}/.dotfiles-terminator-state"
readonly PREVIOUS_FILE="${STATE_DIR}/config.previous"
readonly ABSENT_FILE="${STATE_DIR}/config.was_absent"
readonly TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

dry_run=false

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [--dry-run]

Restore the Terminator configuration saved by terminator/install.sh.

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
[[ -d "${STATE_DIR}" ]] || fail "no Terminator install state found in ${STATE_DIR}"
[[ -f "${PREVIOUS_FILE}" || -f "${ABSENT_FILE}" ]] || fail "Terminator install state is incomplete"
[[ ! -L "${TARGET_FILE}" ]] || fail "refusing to replace symbolic link: ${TARGET_FILE}"
[[ ! -e "${TARGET_FILE}" || -f "${TARGET_FILE}" ]] || fail "target is not a regular file: ${TARGET_FILE}"

if [[ "${dry_run}" == true ]]; then
  if [[ -f "${ABSENT_FILE}" ]]; then
    printf 'Would remove: %s\n' "${TARGET_FILE}"
  else
    printf 'Would restore: %s\n' "${TARGET_FILE}"
  fi
  exit 0
fi

if [[ -f "${TARGET_FILE}" ]]; then
  backup_file="${TARGET_FILE}.uninstall-backup.${TIMESTAMP}"
  if [[ -e "${backup_file}" ]]; then
    backup_file="${backup_file}.$$"
  fi
  cp -p -- "${TARGET_FILE}" "${backup_file}"
  printf 'Backed up current %s to %s\n' "${TARGET_FILE}" "${backup_file}"
fi

if [[ -f "${ABSENT_FILE}" ]]; then
  rm -f -- "${TARGET_FILE}"
  printf 'Removed: %s\n' "${TARGET_FILE}"
else
  cp -p -- "${PREVIOUS_FILE}" "${TARGET_FILE}"
  printf 'Restored: %s\n' "${TARGET_FILE}"
fi

rm -f -- "${PREVIOUS_FILE}" "${ABSENT_FILE}"
if rmdir -- "${STATE_DIR}" 2>/dev/null; then
  printf 'Removed install state: %s\n' "${STATE_DIR}"
else
  printf 'Preserved non-empty install state directory: %s\n' "${STATE_DIR}"
fi

printf 'Terminator configuration uninstall complete. Restart Terminator to use the restored settings.\n'
