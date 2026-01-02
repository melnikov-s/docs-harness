# docs-harness

Give AI coding agents persistent context across sessions.

## The Problem

AI agents lose context between sessions. Each new session rediscovers architecture, features, and in-progress work from scratch.

## The Solution

A structured documentation harness that agents read and maintain automatically:

```
your-repo/
├── AGENTS.md                  # Agent entry point
└── docs/
    ├── architecture/          # HOW it's built (stable)
    ├── features/              # WHAT it does (stable)
    └── plans/                 # Current work (ephemeral)
```

## Requirements

- bash, awk, mktemp, git
- curl (for install only)

## Install

```bash
# One-liner install
curl -fsSL https://raw.githubusercontent.com/melnikov-s/docs-harness/main/install.sh | bash

# Manual install (no curl | bash)
# Download docs-harness.sh and place it on your PATH:
curl -o ~/.local/bin/docs-harness https://raw.githubusercontent.com/melnikov-s/docs-harness/main/docs-harness.sh
chmod +x ~/.local/bin/docs-harness
```

## Usage

```bash
docs-harness                      # Scaffold/sync docs
docs-harness add-plan "X" "Y"     # Add a plan
docs-harness add-arch "X" "Y"     # Add architecture doc
docs-harness add-feature "X" "Y"  # Add feature doc
docs-harness --check              # Validate structure + markers
docs-harness --print-agents       # Print canonical AGENTS block
```

## How It Works

### Sync Behavior

Running `docs-harness` is safe to repeat:

- Creates missing files
- Updates managed content (between markers)
- **Preserves** user-added rows in index tables
- Never deletes content outside markers

### Marker Safety

The tool requires BOTH start and end markers before replacing content:

- If markers are mismatched, it warns and appends a fresh block
- If you see duplicate harness blocks, remove the orphaned marker block manually and re-run `docs-harness`

### Status Values

Consistent across all files:

- **Done** — Complete, ready to merge or shipped
- **In Progress** — Currently being worked on
- **Paused** — Blocked or deprioritized
- **Planned** — Scoped but not started

## Example

See [`examples/demo-project/`](examples/demo-project/) for a complete example.

## License

MIT
