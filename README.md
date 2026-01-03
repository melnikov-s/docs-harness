# docs-harness

Give AI coding agents persistent context across sessions.

## Setup

```bash
curl -fsSL https://raw.githubusercontent.com/melnikov-s/docs-harness/main/init.sh | bash
```

Give this to your agent:

```
Run: curl -fsSL https://raw.githubusercontent.com/melnikov-s/docs-harness/main/init.sh | bash

Then do as the output instructs.
```

Creates:

- `AGENTS.md` — Protocol for agents
- `context/_index.csv` — Work index

## Usage

Start any agent session with:

```
Read AGENTS.md
```

Save work to context:

```
Read AGENTS.md and save this to context: [describe the work]
```

## Upgrades

Re-run the curl command. It replaces the protocol inside `<docs-harness>` tags while preserving any custom content outside the tags. Your context docs are never touched.

## License

MIT
