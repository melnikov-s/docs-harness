#!/usr/bin/env bash
#
# docs-harness init script
# 
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/melnikov-s/docs-harness/main/init.sh | bash
#
# Creates:
#   - AGENTS.md (entry point and protocol for AI agents)
#   - context/_index.md (tracks all work)
#

set -euo pipefail

# Colors
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' CYAN='' NC=''
fi

# Check if in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Not in a git repository${NC}"
fi

# Create context directory
mkdir -p context

# Create context/_index.md
if [[ ! -f "context/_index.md" ]]; then
    cat > "context/_index.md" << 'INDEXEOF'
# Context

Work completed and in progress.

| Doc | Status | Description |
|-----|--------|-------------|
INDEXEOF
    echo -e "${GREEN}✓${NC} Created: context/_index.md"
else
    echo -e "${YELLOW}○${NC} Exists: context/_index.md"
fi

# Create AGENTS.md
if [[ ! -f "AGENTS.md" ]]; then
    cat > "AGENTS.md" << 'AGENTSEOF'
# AGENTS.md

This file is the entry point for AI coding agents working in this repository.

---

## Overview

[TODO: What is this application? What problem does it solve? Who is it for? What are its main capabilities?]

---

## Architecture

[TODO: Technical design overview - app type, frontend, backend, data layer, key dependencies, directory structure]

---

## Context

All project work (in progress and completed) is tracked in [context/_index.md](context/_index.md).

---

## Protocol

### Starting a Session

1. **Read this file** — Understand the app (Overview, Architecture)
2. **Read `context/_index.md`** — See what work exists
3. **Read any "In Progress" docs** — Understand current work
4. **Start working**

---

### Creating a Context Doc

When the user asks you to "save this to context" or when starting substantial work:

1. **Create a file in `context/`** named descriptively (e.g., `auth-system.md`, `api-redesign.md`)

2. **Use this format:**

```markdown
# [Name]

**Status**: In Progress

## Goal

[What are we trying to accomplish?]

## Context

[Background: why this work is needed, what problem it solves]

## Decisions

[Key decisions made and their rationale - this is critical for future agents]

## Approach

[How we're implementing this]

## Progress

### [Date]

- [What was done]

## Open Questions

- [Unresolved questions or blockers]
```

3. **Add a row to `context/_index.md`:**

```markdown
| [Name](filename.md) | In Progress | Brief description |
```

---

### What to Save in Context Docs

**Always capture:**
- The goal and why it matters
- Key decisions and WHY they were made (future agents need rationale)
- Technical approach and implementation details
- Any constraints or tradeoffs
- What was discussed with the user
- Open questions or blockers

**The context doc should allow a future agent to:**
- Understand what was decided without re-asking the user
- Continue the work without losing context
- Know why certain approaches were chosen or rejected

---

### Updating Context During Work

As you work, update the context doc:

- **Progress section**: Add dated entries for significant work
- **Decisions section**: Add new decisions with rationale
- **Open Questions**: Note anything unresolved

---

### Before Ending Your Session (REQUIRED)

You MUST update context docs before finishing:

1. **Progress**: Add what you accomplished
2. **Decisions**: Document any decisions made
3. **Open Questions**: Note anything unresolved

**The context doc is the source of truth.** Do not consider work complete until it reflects what you did and decided.

---

### Completing Work

When work is done:

1. Update status to **Done** in the doc
2. Update status to **Done** in `context/_index.md`
3. Clean up: remove Progress/Open Questions sections if no longer relevant
4. Ensure Decisions section captures all important choices

---

### When to Create Context Docs

**Create context docs for:**
- New features or capabilities
- Major refactors or redesigns
- Complex implementations spanning multiple sessions
- Work where decisions need to be preserved

**Do NOT create context docs for:**
- Bug fixes
- Small changes
- One-off questions
- Work you'll complete immediately

---

## Status Values

- **In Progress** — Currently being worked on
- **Done** — Complete
AGENTSEOF
    echo -e "${GREEN}✓${NC} Created: AGENTS.md"
else
    echo -e "${YELLOW}○${NC} Exists: AGENTS.md"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo -e "${CYAN}Next step:${NC} Run this prompt with your AI agent to seed the Overview and Architecture:"
echo ""
echo "────────────────────────────────────────────────────────────────"
cat << 'PROMPTEOF'
Read AGENTS.md and fill in the Overview and Architecture sections based on this codebase.

For **Overview**, describe:
- What is this application?
- What problem does it solve?
- Who is it for?
- What are its main capabilities?

For **Architecture**, describe:
- What type of app is this? (web app, CLI tool, library, mobile app, etc.)
- Frontend: framework, key libraries, component structure
- Backend: language, framework, API design, key services
- Data: database, storage, state management approach
- Key dependencies and external integrations
- High-level directory structure and organization

Be concise but comprehensive. Future agents will rely on this for context.
PROMPTEOF
echo "────────────────────────────────────────────────────────────────"
echo ""
