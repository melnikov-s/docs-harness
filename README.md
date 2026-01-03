# docs-harness

Give AI coding agents persistent context across sessions.

## Setup

```bash
curl -fsSL https://raw.githubusercontent.com/melnikov-s/docs-harness/main/init.sh | bash
```

This creates:

- `AGENTS.md` — Protocol for agents
- `context/overview.md` — What is this app
- `context/architecture.md` — How it's built
- `context/_index.csv` — Work index

Then run the seeding prompt (output by the script) to fill in overview and architecture.

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

Re-run the curl command. It replaces the protocol in AGENTS.md while preserving your overview.md, architecture.md, and context docs.

## License

MIT
