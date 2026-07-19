# dotcodex

Personal, portable defaults for Codex. The repository tracks only durable personal
guidance and settings; credentials, session history, project trust records, and
machine-specific UI state are intentionally excluded.

## Contents

```text
dotcodex/
├── .codex/
│   ├── AGENTS.md
│   └── config.toml
├── .gitignore
├── install.sh
├── uninstall.sh
└── README.md
```

The tracked `config.toml` contains only these personal defaults:

```toml
model = "gpt-5.6-sol"
model_reasoning_effort = "xhigh"
sandbox_mode = "danger-full-access"
approval_policy = "never"
```

`danger-full-access` together with `approval_policy = "never"` gives Codex full
filesystem and network access without interactive approval prompts. Use this
configuration only on machines and repositories you trust.

## One-line install

After the repository has been pushed to GitHub, install without cloning it:

```bash
curl -fsSL https://raw.githubusercontent.com/emoPointer/dotcodex/main/install.sh | bash
```

Or use `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/emoPointer/dotcodex/main/install.sh | bash
```

The downloaded installer fetches `.codex/AGENTS.md` and `.codex/config.toml`
from the same Git ref, then performs the normal installation. Review remote
scripts before piping them into a shell, especially because this repository
configures Codex for full access.

To preview a remote installation:

```bash
curl -fsSL https://raw.githubusercontent.com/emoPointer/dotcodex/main/install.sh | bash -s -- --dry-run
```

## Install from a clone

Clone the repository, inspect its contents, and run the installer:

```bash
git clone https://github.com/emoPointer/dotcodex.git
cd dotcodex
./install.sh --dry-run
./install.sh
```

The installer targets `~/.codex` by default. It performs two operations:

1. Installs `AGENTS.md` exactly as tracked.
2. Merges only `model`, `model_reasoning_effort`, `sandbox_mode`, and
   `approval_policy` into the existing `config.toml`.

Before changing an existing file, the installer creates a timestamped sibling
backup such as `config.toml.backup.20260720-120000`. It also records the original
managed state in `~/.codex/.dotcodex-state` for safe uninstallation. Existing
machine-specific sections such as `[projects]`, `[tui]`, and `[notice]` remain
untouched.

Start a new Codex session after installation so the new defaults are loaded.

## Alternate Codex home

Set `CODEX_HOME` to install into another location, which is also useful for
testing:

```bash
CODEX_HOME=/path/to/codex-home ./install.sh
```

The same variable works with a remote installation:

```bash
curl -fsSL https://raw.githubusercontent.com/emoPointer/dotcodex/main/install.sh | CODEX_HOME=/path/to/codex-home bash
```

## Uninstall

From a cloned repository:

```bash
./uninstall.sh --dry-run
./uninstall.sh
```

Without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/emoPointer/dotcodex/main/uninstall.sh | bash
```

The uninstaller uses `~/.codex/.dotcodex-state` created by the installer. It
restores the previous `AGENTS.md` and only the four managed `config.toml` keys,
so project trust records and UI state created after installation remain intact.
Before restoring or removing a current file, it creates an
`*.uninstall-backup.*` safety copy.

If an installation made no changes because the target already matched, no
rollback state is recorded for that file and the uninstaller leaves it alone.

## Updating

Edit the tracked files in `.codex/`, review the Git diff, and run `./install.sh`
again. Remote installations use the `main` branch by default; override it with
`DOTCODEX_REF` when testing another published ref. Do not add `auth.json`,
history, sessions, logs, caches, database files, API keys, or other secrets to
this repository.
