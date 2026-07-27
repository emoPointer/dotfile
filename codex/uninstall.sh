#!/usr/bin/env bash
# Purpose: safely undo changes previously made by codex/install.sh.
# Inputs: rollback state stored in CODEX_HOME/.dotfiles-codex-state.
# Outputs: restored AGENTS.md and restored managed keys in config.toml.
# Prerequisites: Bash, awk, grep, cmp, cp, mktemp, and a writable CODEX_HOME.
# Usage: ./uninstall.sh [--dry-run]
# Parameters: CODEX_HOME overrides the default target (~/.codex); --dry-run previews changes.
# File effects: restores or removes managed content and creates uninstall safety backups.

set -euo pipefail

readonly TARGET_DIR="${CODEX_HOME:-${HOME}/.codex}"
readonly STATE_DIR="${TARGET_DIR}/.dotfiles-codex-state"
readonly TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

dry_run=false
temporary_file=""

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [--dry-run]

Undo changes recorded by codex/install.sh. Only the four managed config keys
are reverted, so later machine-specific sections remain in place.

Options:
  --dry-run  Show which files would change without modifying them.
  -h, --help Show this help text.
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "${temporary_file}" && -f "${temporary_file}" ]]; then
    rm -f -- "${temporary_file}"
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

[[ -d "${STATE_DIR}" ]] || fail "no Codex install state found in ${STATE_DIR}"

backup_current_file() {
  local target="$1"
  local backup="${target}.uninstall-backup.${TIMESTAMP}"

  if [[ -e "${backup}" ]]; then
    backup="${backup}.$$"
  fi
  cp -p -- "${target}" "${backup}"
  printf 'Backed up current %s to %s\n' "${target}" "${backup}"
}

clear_file_state() {
  local name="$1"

  rm -f -- "${STATE_DIR}/${name}.previous" "${STATE_DIR}/${name}.was_absent"
}

restore_exact_file() {
  local name="$1"
  local target="$2"
  local previous="${STATE_DIR}/${name}.previous"
  local absent="${STATE_DIR}/${name}.was_absent"

  if [[ ! -f "${previous}" ]]; then
    printf 'Not managed by this installation: %s\n' "${target}"
    return
  fi
  [[ ! -L "${target}" ]] || fail "refusing to replace symbolic link: ${target}"
  [[ ! -e "${target}" || -f "${target}" ]] || fail "target is not a regular file: ${target}"

  if [[ "${dry_run}" == true ]]; then
    if [[ -f "${absent}" ]]; then
      printf 'Would remove: %s\n' "${target}"
    else
      printf 'Would restore: %s\n' "${target}"
    fi
    return
  fi

  if [[ -f "${target}" ]]; then
    backup_current_file "${target}"
  fi
  if [[ -f "${absent}" ]]; then
    rm -f -- "${target}"
    printf 'Removed: %s\n' "${target}"
  else
    cp -p -- "${previous}" "${target}"
    printf 'Restored: %s\n' "${target}"
  fi
  clear_file_state "${name}"
}

restore_config() {
  local target="${TARGET_DIR}/config.toml"
  local previous="${STATE_DIR}/config.toml.previous"
  local absent="${STATE_DIR}/config.toml.was_absent"
  local remove_empty=false

  if [[ ! -f "${previous}" ]]; then
    printf 'Not managed by this installation: %s\n' "${target}"
    return
  fi
  [[ ! -L "${target}" ]] || fail "refusing to replace symbolic link: ${target}"
  [[ ! -e "${target}" || -f "${target}" ]] || fail "target is not a regular file: ${target}"

  if [[ ! -f "${target}" ]]; then
    if [[ "${dry_run}" == true ]]; then
      if [[ ! -f "${absent}" ]]; then
        printf 'Would restore: %s\n' "${target}"
      else
        printf 'Already absent: %s\n' "${target}"
      fi
      return
    fi

    if [[ ! -f "${absent}" ]]; then
      cp -p -- "${previous}" "${target}"
      printf 'Restored: %s\n' "${target}"
    else
      printf 'Already absent: %s\n' "${target}"
    fi
    clear_file_state "config.toml"
    return
  fi

  if [[ "${dry_run}" == true ]]; then
    temporary_file="$(mktemp "${TMPDIR:-/tmp}/dotcodex-uninstall.XXXXXX")"
  else
    temporary_file="$(mktemp "${target}.tmp.XXXXXX")"
  fi

  awk '
    function emit_missing(    i, key) {
      for (i = 1; i <= key_count; i++) {
        key = key_order[i]
        if (!(key in seen)) {
          print previous_value[key]
        }
      }
    }

    FILENAME == ARGV[1] {
      if ($0 ~ /^[[:space:]]*(model|model_reasoning_effort|sandbox_mode|approval_policy)[[:space:]]*=/) {
        key = $0
        sub(/=.*/, "", key)
        gsub(/[[:space:]]/, "", key)
        previous_value[key] = $0
        key_order[++key_count] = key
      }
      next
    }

    !in_table && $0 ~ /^[[:space:]]*\[/ {
      emit_missing()
      in_table = 1
    }

    !in_table && $0 ~ /^[[:space:]]*(model|model_reasoning_effort|sandbox_mode|approval_policy)[[:space:]]*=/ {
      key = $0
      sub(/=.*/, "", key)
      gsub(/[[:space:]]/, "", key)
      if (key in previous_value) {
        print previous_value[key]
        seen[key] = 1
      }
      next
    }

    { print }

    END {
      if (!in_table) {
        emit_missing()
      }
    }
  ' "${previous}" "${target}" > "${temporary_file}"

  if [[ -f "${absent}" ]] && ! grep -Eq '^[[:space:]]*[^#[:space:]]' "${temporary_file}"; then
    remove_empty=true
  fi

  if [[ "${remove_empty}" == false ]] && cmp -s -- "${temporary_file}" "${target}"; then
    if [[ "${dry_run}" == true ]]; then
      printf 'Already reverted: %s\n' "${target}"
      return
    fi
    rm -f -- "${temporary_file}"
    temporary_file=""
    clear_file_state "config.toml"
    printf 'Already reverted: %s\n' "${target}"
    return
  fi

  if [[ "${dry_run}" == true ]]; then
    if [[ "${remove_empty}" == true ]]; then
      printf 'Would remove: %s\n' "${target}"
    else
      printf 'Would restore managed defaults in: %s\n' "${target}"
    fi
    return
  fi

  backup_current_file "${target}"
  if [[ "${remove_empty}" == true ]]; then
    rm -f -- "${target}"
    rm -f -- "${temporary_file}"
    temporary_file=""
    printf 'Removed: %s\n' "${target}"
  else
    mv -- "${temporary_file}" "${target}"
    temporary_file=""
    printf 'Restored managed defaults in: %s\n' "${target}"
  fi
  clear_file_state "config.toml"
}

restore_exact_file "AGENTS.md" "${TARGET_DIR}/AGENTS.md"
restore_config

if [[ "${dry_run}" != true ]]; then
  rm -f -- "${STATE_DIR}/version"
  if rmdir -- "${STATE_DIR}" 2>/dev/null; then
    printf 'Removed install state: %s\n' "${STATE_DIR}"
  else
    printf 'Preserved non-empty install state directory: %s\n' "${STATE_DIR}"
  fi
fi

printf 'Codex configuration uninstall complete. Start a new Codex session to use the restored settings.\n'
