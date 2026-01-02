# AGENTS.md

This file serves as the entry point for AI coding agents working in this repository.

<!-- DOCS_HARNESS:START -->

## Documentation

> **Agents**: Read this section first. This is your persistent context across sessions.

| Need                     | Location                                                    |
| ------------------------ | ----------------------------------------------------------- |
| How the system is built  | [docs/architecture/\_index.md](docs/architecture/_index.md) |
| What features exist      | [docs/features/\_index.md](docs/features/_index.md)         |
| What we are building now | [docs/plans/\_index.md](docs/plans/_index.md)               |

---

### Prerequisites

The `docs-harness` command is an **external CLI tool** that must be installed on the system.

- **Check if installed**: Run `which docs-harness` or `docs-harness --version`
- **If not installed**: See https://github.com/melnikov-s/docs-harness for installation
- **Do NOT create your own implementation** — use the installed CLI

---

### Cold Start Protocol (New Session)

1. **Read `docs/plans/_index.md`** — Check for in-progress work
2. **Read the active plan file** (if any) — Understand what has been done
3. **Read `docs/architecture/_index.md`** — Understand how it is built
4. **Read `docs/features/_index.md`** — Understand what it does
5. **Start working** — You now have full context

---

### Maintenance Protocol

#### Starting New Work

1. Run: `docs-harness add-plan "Name" "Description"`
2. Edit the created plan file with context and approach
3. Update the Progress Log as you work

#### During Work

- Update the plan Progress Log with dated entries
- Log decisions with rationale (future agents need to know WHY)
- Track files changed

#### Session End

Update the plan with:

- Current status
- Clear "Next Steps" for the next agent
- Any blockers or open questions

#### Work Complete

1. Mark plan status as Done
2. Merge findings into `docs/architecture/` or `docs/features/`
3. Remove plan row from `docs/plans/_index.md`
4. Delete the plan file

---

### When to Use Plans

Plans are for **substantial work that may span multiple sessions**:

- New features, major refactors, multi-step implementations

**Do not create plans for**:

- Bug fixes, quick changes, debugging
- One-off tasks you will complete in this session
- Questions or research

---

### Status Values

- **Done** — Complete, ready to merge or already shipped
- **In Progress** — Currently being worked on
- **Paused** — Blocked or deprioritized
- **Planned** — Scoped but not started
<!-- DOCS_HARNESS:END -->
