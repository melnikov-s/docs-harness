#!/usr/bin/env bash
#
# docs-harness init script
# 
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/melnikov-s/docs-harness/main/init.sh | bash
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

HARNESS_START="<docs-harness>"
HARNESS_END="</docs-harness>"

# The managed AGENTS.md content
AGENTS_CONTENT='<docs-harness>
# AGENTS.md

Read [context/overview.md](context/overview.md) and [context/architecture.md](context/architecture.md) first.

## Context

Work in progress and completed: [context/_index.csv](context/_index.csv)

## Protocol

### Starting a Session

1. Read overview.md and architecture.md
2. Read _index.csv — check for In Progress work
3. Read any In Progress context docs
4. Start working

### Creating Context Docs

For substantial work, create `context/[name].md`:

```
# Name
**Status**: In Progress

## Goal
[What we are accomplishing]

## Decisions
[Key decisions and WHY - critical for future agents]

## Progress
### [Date]
- [What was done]
```

Add to _index.csv: `filename.md,In Progress,description`

### Before Ending (REQUIRED)

Update context docs with:
- Progress: what you accomplished
- Decisions: choices made and rationale

### When Done

Update status to Done in doc and _index.csv.

### When NOT to Create Docs

Bug fixes, small changes, one-off questions.

## Status

- In Progress
- Done
</docs-harness>'

# Check if in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Not in a git repository${NC}"
fi

# Create context directory
mkdir -p context

# Create context/_index.csv (if not exists)
if [[ ! -f "context/_index.csv" ]]; then
    echo "file,status,description" > "context/_index.csv"
    echo -e "${GREEN}✓${NC} Created: context/_index.csv"
fi

# Create context/overview.md (if not exists)
if [[ ! -f "context/overview.md" ]]; then
    cat > "context/overview.md" << 'EOF'
# Overview

[TODO: What is this application? What problem does it solve? Who is it for?]
EOF
    echo -e "${GREEN}✓${NC} Created: context/overview.md"
fi

# Create context/architecture.md (if not exists)
if [[ ! -f "context/architecture.md" ]]; then
    cat > "context/architecture.md" << 'EOF'
# Architecture

[TODO: App type, key technologies, high-level structure]
EOF
    echo -e "${GREEN}✓${NC} Created: context/architecture.md"
fi

# Create or upgrade AGENTS.md
if [[ ! -f "AGENTS.md" ]]; then
    # New file
    printf '%s\n' "$AGENTS_CONTENT" > "AGENTS.md"
    echo -e "${GREEN}✓${NC} Created: AGENTS.md"
elif grep -qF "$HARNESS_START" "AGENTS.md"; then
    # Upgrade: replace content between tags
    start_line=$(grep -nF "$HARNESS_START" "AGENTS.md" | head -1 | cut -d: -f1)
    end_line=$(grep -nF "$HARNESS_END" "AGENTS.md" | head -1 | cut -d: -f1)
    
    if [[ -n "$start_line" && -n "$end_line" ]]; then
        # Get content before and after
        if [[ "$start_line" -gt 1 ]]; then
            head -n $((start_line - 1)) "AGENTS.md" > "AGENTS.md.tmp"
        else
            : > "AGENTS.md.tmp"  # Empty file
        fi
        printf '%s\n' "$AGENTS_CONTENT" >> "AGENTS.md.tmp"
        tail -n +$((end_line + 1)) "AGENTS.md" >> "AGENTS.md.tmp"
        mv "AGENTS.md.tmp" "AGENTS.md"
        echo -e "${GREEN}↻${NC} Upgraded: AGENTS.md"
    else
        echo -e "${YELLOW}⚠${NC} Could not find matching tags, skipping upgrade"
    fi
else
    # Old format without tags - backup and replace
    mv "AGENTS.md" "AGENTS.md.backup"
    echo "$AGENTS_CONTENT" > "AGENTS.md"
    echo -e "${YELLOW}⚠${NC} Replaced AGENTS.md (backup: AGENTS.md.backup)"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo -e "${CYAN}Next:${NC} Run this prompt with your agent:"
echo ""
echo "────────────────────────────────────────────────────────────────"
cat << 'PROMPTEOF'
Read the codebase and fill in context/overview.md and context/architecture.md.

For overview.md (~300 words):
- What is this application?
- What problem does it solve?
- Who is it for?
- What are its main capabilities?

For architecture.md (~150 words):
- App type (web, CLI, library, etc.)
- Key technologies (frontend, backend, database)
- High-level directory structure

Be concise. These files are read by agents at the start of every session.
PROMPTEOF
echo "────────────────────────────────────────────────────────────────"
echo ""
