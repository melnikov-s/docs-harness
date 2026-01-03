# docs-harness

Give AI coding agents persistent context across sessions.

## Setup

```bash
curl -fsSL https://raw.githubusercontent.com/melnikov-s/docs-harness/main/init.sh | bash
```

Creates:

- `AGENTS.md` — Protocol for agents
- `context/_index.csv` — Work index

Then run the seeding prompt (output by the script) to have your agent create overview and architecture docs.

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
