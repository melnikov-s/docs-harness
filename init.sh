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

## Context

Work in progress: [context/_index.csv](context/_index.csv)

## Protocol

### Starting a Session

1. Read _index.csv — see active work
2. Read docs listed in _index.csv
3. If applicable, read overview.md and/or architecture.md
4. If user requests work on a topic, read relevant context docs
5. Start working

### Creating Context Docs

For substantial work, create `context/[name].md`:

```
# Name

## Goal
[What we are accomplishing]

## Decisions
[Key decisions and WHY - critical for future agents]

## Progress
### [Date]
- [What was done]
```

Add to _index.csv: `filename.md,description`

### Before Ending (REQUIRED)

Update context docs with:
- Progress: what you accomplished
- Decisions: choices made and rationale

### When Done

Remove the row from _index.csv. The doc stays in context/ for future reference.

### When NOT to Create Docs

Bug fixes, small changes, one-off questions.
</docs-harness>'

# Check if in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Not in a git repository${NC}"
fi

# Track if this is a fresh install
FRESH_INSTALL=false

# Create context directory
mkdir -p context

# Create context/_index.csv (if not exists)
if [[ ! -f "context/_index.csv" ]]; then
    echo "file,description" > "context/_index.csv"
    echo -e "${GREEN}✓${NC} Created: context/_index.csv"
    FRESH_INSTALL=true
fi

# Create or upgrade AGENTS.md
if [[ ! -f "AGENTS.md" ]]; then
    # New file
    printf '%s\n' "$AGENTS_CONTENT" > "AGENTS.md"
    echo -e "${GREEN}✓${NC} Created: AGENTS.md"
    FRESH_INSTALL=true
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
    printf '%s\n' "$AGENTS_CONTENT" > "AGENTS.md"
    echo -e "${YELLOW}⚠${NC} Replaced AGENTS.md (backup: AGENTS.md.backup)"
    FRESH_INSTALL=true
fi

echo ""
echo -e "${GREEN}Done!${NC}"

# Only show seeding prompt on fresh install
if $FRESH_INSTALL; then
    echo ""
    echo -e "${CYAN}Next:${NC} Run this prompt with your agent:"
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    cat << 'PROMPTEOF'
Read AGENTS.md, then create context docs for this codebase:

1. Create context/overview.md (~300 words):
   - What is this application?
   - What problem does it solve?
   - Who is it for?

2. Create context/architecture.md (~150 words):
   - App type and key technologies
   - High-level structure

Be concise. These are read at the start of every session.
PROMPTEOF
    echo "────────────────────────────────────────────────────────────────"
    echo ""
fi
