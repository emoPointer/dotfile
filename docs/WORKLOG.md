# Work log

## 2026-07-27 17:37 CST — Add one-command remote installation

- Operation: extended the Codex and Terminator installers to download their
  source configuration from the public GitHub repository when executed through
  standard input; documented `curl | bash` and `wget | bash` installation and
  remote uninstallation commands.
- Purpose: allow a new machine to import either configuration with one command
  and without cloning the repository.
- Affected scope: both application install scripts and application READMEs.
- Commands executed: Bash syntax and diff checks; isolated local-file and
  streamed-script installation/uninstallation round trips for Codex and
  Terminator; sensitive-content, personal-path, and stale-documentation scans.
- Validation result: all four local/streamed round trips passed. Streamed
  installers downloaded the tracked configuration from the public repository,
  and the uninstallers restored or removed it as expected.
- Remaining risk: remote installation requires network access and either
  `curl` or `wget`; piping a remote script to Bash should only be done after
  reviewing the script.

## 2026-07-27 17:30 CST — Migrate personal configurations to dotfile layout

- Operation: reorganized the existing Codex files under `codex/`, extracted the
  local Terminator configuration into `terminator/`, and added scoped install,
  rollback, and usage documentation.
- Purpose: make the repository the single private home for multiple personal
  application configurations before moving it from `dotcodex` to `dotfile`.
- Affected scope: root documentation and ignore rules, Codex configuration and
  scripts, Terminator configuration and scripts.
- Commands executed: Bash syntax checks; sensitive-content and absolute-home
  path scans; isolated install/uninstall round trips using temporary
  `CODEX_HOME` and `XDG_CONFIG_HOME` directories; ConfigObj parsing of the
  Terminator config; `git diff --check`.
- Validation result: all four existing/absent configuration round trips passed;
  the already-matching Terminator case remained a no-op; the extracted file
  matched the active local config byte for byte; no embedded home path or
  credential was found.
- Remaining risk: the installers were intentionally not run against the active
  home-directory configurations; applications must be restarted after a real
  import.
