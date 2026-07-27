#!/usr/bin/env bash
# Purpose: install the tracked Terminator configuration.
# Inputs: a local config file or a copy downloaded from the public repository.
# Outputs: XDG_CONFIG_HOME/terminator/config (defaults to ~/.config/terminator/config).
# Prerequisites: Bash, standard Unix tools, and curl or wget for remote installation.
# Usage: ./install.sh [--dry-run]
# Parameters: XDG_CONFIG_HOME changes the target; DOTFILES_REF changes the remote Git ref.
# File effects: creates or replaces config, records rollback state, and creates a backup.

set -euo pipefail

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fi
readonly SCRIPT_DIR
readonly TARGET_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/terminator"
readonly TARGET_FILE="${TARGET_DIR}/config"
readonly STATE_DIR="${TARGET_DIR}/.dotfiles-terminator-state"
readonly PREVIOUS_FILE="${STATE_DIR}/config.previous"
readonly ABSENT_FILE="${STATE_DIR}/config.was_absent"
readonly TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
readonly DOTFILES_REPOSITORY="${DOTFILES_REPOSITORY:-emoPointer/dotfile}"
readonly DOTFILES_REF="${DOTFILES_REF:-main}"
readonly DOTFILES_RAW_BASE="${DOTFILES_RAW_BASE:-https://raw.githubusercontent.com/${DOTFILES_REPOSITORY}/${DOTFILES_REF}}"

dry_run=false
download_directory=""
source_file="${SCRIPT_DIR:+${SCRIPT_DIR}/config}"

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

cleanup() {
  if [[ -n "${download_directory}" && -d "${download_directory}" ]]; then
    rm -rf -- "${download_directory}"
  fi
}

trap cleanup EXIT

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

download_file() {
  local url="$1"
  local destination="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 --connect-timeout 15 "${url}" -o "${destination}"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --tries=3 --timeout=15 -O "${destination}" "${url}"
  else
    fail "remote installation requires curl or wget"
  fi
}

prepare_source() {
  if [[ -n "${source_file}" && -f "${source_file}" ]]; then
    return
  fi

  download_directory="$(mktemp -d "${TMPDIR:-/tmp}/dotfile-terminator-download.XXXXXX")"
  source_file="${download_directory}/config"
  download_file "${DOTFILES_RAW_BASE}/terminator/config" "${source_file}"
  printf 'Downloaded Terminator configuration from %s (%s).\n' "${DOTFILES_REPOSITORY}" "${DOTFILES_REF}"
}

prepare_source

[[ "${TARGET_DIR}" == /* ]] || fail "target directory must be an absolute path: ${TARGET_DIR}"
[[ -f "${source_file}" ]] || fail "missing source file: ${source_file}"
[[ ! -L "${TARGET_FILE}" ]] || fail "refusing to replace symbolic link: ${TARGET_FILE}"
[[ ! -e "${TARGET_FILE}" || -f "${TARGET_FILE}" ]] || fail "target is not a regular file: ${TARGET_FILE}"

if [[ -f "${TARGET_FILE}" ]] && cmp -s -- "${source_file}" "${TARGET_FILE}"; then
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

cp -- "${source_file}" "${TARGET_FILE}"
printf 'Installed: %s\n' "${TARGET_FILE}"
printf 'Terminator configuration installation complete. Restart Terminator to use it.\n'
