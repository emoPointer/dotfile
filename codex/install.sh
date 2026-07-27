#!/usr/bin/env bash
# Purpose: install the tracked Codex guidance and personal defaults into CODEX_HOME.
# Inputs: AGENTS.md and config.toml beside this script.
# Outputs: CODEX_HOME/AGENTS.md and an updated CODEX_HOME/config.toml.
# Prerequisites: Bash and standard Unix tools.
# Usage: ./install.sh [--dry-run]
# Parameters: CODEX_HOME changes the target.
# File effects: creates or updates files, writes rollback state, and creates safety backups.

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly TARGET_DIR="${CODEX_HOME:-${HOME}/.codex}"
readonly STATE_DIR="${TARGET_DIR}/.dotfiles-codex-state"
readonly TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
readonly MANAGED_KEYS=(
  model
  model_reasoning_effort
  sandbox_mode
  approval_policy
)

dry_run=false
temporary_file=""
readonly SOURCE_DIRECTORY="${SCRIPT_DIR}"

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run]

Install the tracked Codex guidance and merge the tracked personal defaults into
CODEX_HOME/config.toml. CODEX_HOME defaults to ~/.codex.

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

for source_file in "${SOURCE_DIRECTORY}/AGENTS.md" "${SOURCE_DIRECTORY}/config.toml"; do
  [[ -f "${source_file}" ]] || fail "missing source file: ${source_file}"
done

for key in "${MANAGED_KEYS[@]}"; do
  match_count="$(grep -Ec "^[[:space:]]*${key}[[:space:]]*=" "${SOURCE_DIRECTORY}/config.toml" || true)"
  [[ "${match_count}" == "1" ]] || fail "expected exactly one ${key} entry in codex/config.toml"
done

ensure_state_directory() {
  mkdir -p -- "${STATE_DIR}"
  chmod 700 -- "${STATE_DIR}"
  if [[ ! -f "${STATE_DIR}/version" ]]; then
    printf '1\n' > "${STATE_DIR}/version"
  fi
}

record_original_file() {
  local name="$1"
  local target="$2"
  local previous="${STATE_DIR}/${name}.previous"
  local absent="${STATE_DIR}/${name}.was_absent"

  if [[ -e "${previous}" || -e "${absent}" ]]; then
    return
  fi

  ensure_state_directory
  if [[ -f "${target}" ]]; then
    cp -p -- "${target}" "${previous}"
  else
    : > "${previous}"
    : > "${absent}"
  fi
  chmod 600 -- "${previous}"
}

backup_file() {
  local target="$1"
  local backup="${target}.backup.${TIMESTAMP}"

  if [[ -e "${backup}" ]]; then
    backup="${backup}.$$"
  fi
  cp -p -- "${target}" "${backup}"
  printf 'Backed up %s to %s\n' "${target}" "${backup}"
}

install_exact_file() {
  local source="$1"
  local target="$2"

  [[ ! -L "${target}" ]] || fail "refusing to replace symbolic link: ${target}"
  if [[ -f "${target}" ]] && cmp -s -- "${source}" "${target}"; then
    printf 'Unchanged: %s\n' "${target}"
    return
  fi
  [[ ! -e "${target}" || -f "${target}" ]] || fail "target is not a regular file: ${target}"

  if [[ "${dry_run}" == true ]]; then
    printf 'Would install: %s\n' "${target}"
    return
  fi

  record_original_file "AGENTS.md" "${target}"
  if [[ -f "${target}" ]]; then
    backup_file "${target}"
  fi
  cp -- "${source}" "${target}"
  printf 'Installed: %s\n' "${target}"
}

merge_config() {
  local source="$1"
  local target="$2"

  [[ ! -L "${target}" ]] || fail "refusing to replace symbolic link: ${target}"
  if [[ ! -e "${target}" ]]; then
    if [[ "${dry_run}" == true ]]; then
      printf 'Would install: %s\n' "${target}"
    else
      record_original_file "config.toml" "${target}"
      cp -- "${source}" "${target}"
      printf 'Installed: %s\n' "${target}"
    fi
    return
  fi
  [[ -f "${target}" ]] || fail "target is not a regular file: ${target}"

  if [[ "${dry_run}" == true ]]; then
    temporary_file="$(mktemp "${TMPDIR:-/tmp}/dotcodex-config.XXXXXX")"
  else
    temporary_file="$(mktemp "${target}.tmp.XXXXXX")"
  fi
  awk '
    function emit_missing(    i, key) {
      for (i = 1; i <= key_count; i++) {
        key = key_order[i]
        if (!(key in seen)) {
          print desired[key]
        }
      }
    }

    NR == FNR {
      if ($0 ~ /^[[:space:]]*(model|model_reasoning_effort|sandbox_mode|approval_policy)[[:space:]]*=/) {
        key = $0
        sub(/=.*/, "", key)
        gsub(/[[:space:]]/, "", key)
        desired[key] = $0
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
      print desired[key]
      seen[key] = 1
      next
    }

    { print }

    END {
      if (!in_table) {
        emit_missing()
      }
    }
  ' "${source}" "${target}" > "${temporary_file}"

  if cmp -s -- "${temporary_file}" "${target}"; then
    printf 'Unchanged: %s\n' "${target}"
    rm -f -- "${temporary_file}"
    temporary_file=""
    return
  fi

  if [[ "${dry_run}" == true ]]; then
    printf 'Would update managed defaults in: %s\n' "${target}"
    return
  fi

  record_original_file "config.toml" "${target}"
  backup_file "${target}"
  mv -- "${temporary_file}" "${target}"
  temporary_file=""
  printf 'Updated managed defaults in: %s\n' "${target}"
}

if [[ "${dry_run}" != true ]]; then
  mkdir -p -- "${TARGET_DIR}"
fi

install_exact_file "${SOURCE_DIRECTORY}/AGENTS.md" "${TARGET_DIR}/AGENTS.md"
merge_config "${SOURCE_DIRECTORY}/config.toml" "${TARGET_DIR}/config.toml"

printf 'Codex configuration installation complete. Start a new Codex session to use it.\n'
