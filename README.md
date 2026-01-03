# docs-harness

Give AI coding agents persistent context across sessions.

## The Problem

AI agents lose context between sessions. Every new conversation rediscovers architecture, decisions, and work in progress from scratch.

## The Solution

A simple documentation protocol that agents read and maintain:

```
your-repo/
├── AGENTS.md           # Entry point: Overview, Architecture, Protocol
└── context/
    └── _index.md       # All work (in progress + completed)
```

## Setup

Run in your repository:

```bash
curl -fsSL https://raw.githubusercontent.com/melnikov-s/docs-harness/main/init.sh | bash
```

This creates:

- `AGENTS.md` — Overview, Architecture, and the protocol agents follow
- `context/_index.md` — Index of all work

Then run the seeding prompt (output by the script) to have your agent fill in the Overview and Architecture sections.

## Usage

### Start a session

```
Read AGENTS.md
```

### Create a context doc

```
Read AGENTS.md and save this to context: [describe what you're working on]
```

### Continue work

```
Read AGENTS.md and continue the in-progress work on [feature].
```

## How It Works

AGENTS.md contains:

- **Overview**: What is this app?
- **Architecture**: How is it built?
- **Protocol**: How agents should create, update, and complete context docs

Context docs capture:

- Goals and why they matter
- Decisions and their rationale
- Progress and open questions

This creates persistent memory across agent sessions.

## License

MIT
