#!/usr/bin/env bash
#
# docs-harness - Zero-dependency documentation scaffolding for AI agents
#
# Usage:
#   docs-harness              # Scaffold/sync docs structure
#   docs-harness add-plan     # Add a new plan
#   docs-harness add-arch     # Add architecture doc
#   docs-harness add-feature  # Add feature doc
#   docs-harness --check      # Validate structure
#   docs-harness --help       # Show help
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

VERSION="1.0.0"

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' CYAN='' NC=''
fi

TODAY=$(date +%Y-%m-%d)

# Markers
MARKER_START="<!-- DOCS_HARNESS:START -->"
MARKER_END="<!-- DOCS_HARNESS:END -->"
ARCH_ROWS_START="<!-- DOCS_HARNESS:ARCH_ROWS:START -->"
ARCH_ROWS_END="<!-- DOCS_HARNESS:ARCH_ROWS:END -->"
FEAT_ROWS_START="<!-- DOCS_HARNESS:FEAT_ROWS:START -->"
FEAT_ROWS_END="<!-- DOCS_HARNESS:FEAT_ROWS:END -->"
PLAN_ROWS_START="<!-- DOCS_HARNESS:PLAN_ROWS:START -->"
PLAN_ROWS_END="<!-- DOCS_HARNESS:PLAN_ROWS:END -->"

# ============================================================================
# Embedded Templates
# ============================================================================

# AGENTS.md harness block (between START/END markers)
AGENTS_HARNESS_CONTENT='## Documentation

> **Agents**: Read this section first. This is your persistent context across sessions.

| Need | Location |
|------|----------|
| How the system is built | [docs/architecture/_index.md](docs/architecture/_index.md) |
| What features exist | [docs/features/_index.md](docs/features/_index.md) |
| What we are building now | [docs/plans/_index.md](docs/plans/_index.md) |

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

### Status Values

- **Done** — Complete, ready to merge or already shipped
- **In Progress** — Currently being worked on
- **Paused** — Blocked or deprioritized
- **Planned** — Scoped but not started'

# Architecture index template
ARCH_INDEX_TEMPLATE='# Architecture Documentation

Technical documentation for how this system is built.

| Document | Description |
|----------|-------------|
<!-- DOCS_HARNESS:ARCH_ROWS:START -->
<!-- DOCS_HARNESS:ARCH_ROWS:END -->'

# Features index template
FEAT_INDEX_TEMPLATE='# Features Documentation

Product features and their implementations.

| Feature | Status | Description |
|---------|--------|-------------|
<!-- DOCS_HARNESS:FEAT_ROWS:START -->
<!-- DOCS_HARNESS:FEAT_ROWS:END -->

## Status Values

- **Done** — Complete and shipped
- **In Progress** — Currently being developed
- **Paused** — Blocked or deprioritized
- **Planned** — Designed but not started'

# Plans index template
PLAN_INDEX_TEMPLATE='# Active Plans

Current and upcoming work. **Agents: Check this first when starting a new session.**

| Plan | Status | Description |
|------|--------|-------------|
<!-- DOCS_HARNESS:PLAN_ROWS:START -->
<!-- DOCS_HARNESS:PLAN_ROWS:END -->

## Status Values

- **Done** — Ready to merge into features/architecture
- **In Progress** — Currently being worked on
- **Paused** — Blocked or deprioritized
- **Planned** — Scoped but not started'

# ============================================================================
# Helper Functions
# ============================================================================

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_sync() { echo -e "${GREEN}↻${NC} $1"; }
print_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${CYAN}→${NC} $1"; }

slugify() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
}

# Ensure we're at repo root (require .git or find it)
require_repo_root() {
    if [[ -d ".git" ]]; then
        return 0
    fi
    
    # Try to find git root
    local git_root
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        cd "$git_root"
        return 0
    fi
    
    print_error "Not in a git repository. Run from repo root or inside a git repo."
    exit 1
}

# Check if both markers exist in file
has_marker_pair() {
    local file="$1"
    local start_marker="$2"
    local end_marker="$3"
    
    grep -qF "$start_marker" "$file" && grep -qF "$end_marker" "$file"
}

# ============================================================================
# Marker-Based Content Management (using awk)
# ============================================================================

# Extract content between markers (exclusive of markers)
extract_between_markers() {
    local file="$1"
    local start_marker="$2"
    local end_marker="$3"
    
    awk -v start="$start_marker" -v end="$end_marker" '
        $0 == start { capture=1; next }
        $0 == end { capture=0 }
        capture { print }
    ' "$file"
}

# Replace content between markers (atomic: temp file + move)
# Requires BOTH markers to exist; returns error if not
replace_between_markers() {
    local file="$1"
    local start_marker="$2"
    local end_marker="$3"
    local new_content="$4"
    
    # Safety check: require both markers
    if ! has_marker_pair "$file" "$start_marker" "$end_marker"; then
        return 1
    fi
    
    local tmp_file content_file
    tmp_file=$(mktemp)
    content_file=$(mktemp)
    
    # Write content to temp file for awk to read
    printf '%s\n' "$new_content" > "$content_file"
    
    awk -v start="$start_marker" -v end="$end_marker" -v cfile="$content_file" '
        $0 == start { 
            print
            while ((getline line < cfile) > 0) print line
            close(cfile)
            skip=1
            next 
        }
        $0 == end { 
            skip=0
            print
            next
        }
        !skip { print }
    ' "$file" > "$tmp_file"
    
    mv "$tmp_file" "$file"
    rm -f "$content_file"
}

# Insert a row before the end marker
insert_before_marker() {
    local file="$1"
    local end_marker="$2"
    local row="$3"
    
    local tmp_file
    tmp_file=$(mktemp)
    
    awk -v end="$end_marker" -v row="$row" '
        $0 == end { print row }
        { print }
    ' "$file" > "$tmp_file"
    
    mv "$tmp_file" "$file"
}

# ============================================================================
# AGENTS.md Sync
# ============================================================================

sync_agents_md() {
    local agents_file="AGENTS.md"
    
    # Case 1: File doesn't exist - create with header + harness
    if [[ ! -f "$agents_file" ]]; then
        cat > "$agents_file" << AGENTSEOF
# AGENTS.md

This file serves as the entry point for AI coding agents working in this repository.

${MARKER_START}
${AGENTS_HARNESS_CONTENT}
${MARKER_END}
AGENTSEOF
        print_success "Created: $agents_file"
        return 0
    fi
    
    # Case 2: File exists with BOTH markers - replace content between them
    if has_marker_pair "$agents_file" "$MARKER_START" "$MARKER_END"; then
        replace_between_markers "$agents_file" "$MARKER_START" "$MARKER_END" "$AGENTS_HARNESS_CONTENT"
        print_sync "Synced: $agents_file"
        return 0
    fi
    
    # Case 3: File exists with only one marker (corrupted) - warn and append fresh block
    if grep -qF "$MARKER_START" "$agents_file" || grep -qF "$MARKER_END" "$agents_file"; then
        print_warn "AGENTS.md has mismatched markers. Appending fresh harness block."
        print_info "Manually remove the orphaned marker to clean up."
    fi
    
    # Case 4: File exists without markers - append harness block
    cat >> "$agents_file" << APPENDEOF

${MARKER_START}
${AGENTS_HARNESS_CONTENT}
${MARKER_END}
APPENDEOF
    print_success "Added harness to: $agents_file"
}

# ============================================================================
# Index File Sync (with row preservation)
# ============================================================================

sync_index_file() {
    local file="$1"
    local template="$2"
    local rows_start="$3"
    local rows_end="$4"
    
    mkdir -p "$(dirname "$file")"
    
    # Case 1: File doesn't exist - create from template
    if [[ ! -f "$file" ]]; then
        printf '%s\n' "$template" > "$file"
        print_success "Created: $file"
        return 0
    fi
    
    # Case 2: File exists with BOTH row markers - preserve rows, sync skeleton
    if has_marker_pair "$file" "$rows_start" "$rows_end"; then
        local preserved_rows
        preserved_rows=$(extract_between_markers "$file" "$rows_start" "$rows_end")
        
        # Write template and inject preserved rows
        printf '%s\n' "$template" > "$file.tmp"
        replace_between_markers "$file.tmp" "$rows_start" "$rows_end" "$preserved_rows"
        mv "$file.tmp" "$file"
        print_sync "Synced: $file"
        return 0
    fi
    
    # Case 3: Partial markers (corrupted) - warn and overwrite with template
    if grep -qF "$rows_start" "$file" || grep -qF "$rows_end" "$file"; then
        print_warn "$file has mismatched row markers. Resetting to template."
    fi
    
    # Case 4: Legacy file without markers - upgrade to new format
    # Try to extract existing table rows (lines starting with |, portable grep)
    local legacy_rows
    legacy_rows=$(grep -E '^[[:space:]]*\|' "$file" 2>/dev/null | grep -Ev '^[[:space:]]*\|[-:]+\|' | grep -Ev '^[[:space:]]*\| (Document|Feature|Plan)' || true)
    
    printf '%s\n' "$template" > "$file.tmp"
    if [[ -n "$legacy_rows" ]]; then
        replace_between_markers "$file.tmp" "$rows_start" "$rows_end" "$legacy_rows"
        print_sync "Upgraded: $file (preserved existing rows)"
    else
        print_sync "Upgraded: $file (added markers)"
    fi
    mv "$file.tmp" "$file"
}

# ============================================================================
# Add Commands
# ============================================================================

add_plan() {
    local name="$1"
    local description="$2"
    local slug
    slug=$(slugify "$name")
    local filename="${TODAY}-${slug}.md"
    local filepath="docs/plans/${filename}"
    local index_file="docs/plans/_index.md"
    
    if [[ ! -d "docs/plans" ]]; then
        print_error "docs/plans/ not found. Run 'docs-harness' first."
        exit 1
    fi
    
    if [[ -f "$filepath" ]]; then
        print_error "Plan already exists: $filepath"
        exit 1
    fi
    
    # Create plan file
    cat > "$filepath" << PLANEOF
# ${name}

**Status**: In Progress  
**Started**: ${TODAY}  
**Goal**: ${description}

## Related Docs

<!-- Link to relevant architecture/feature docs for context -->
<!-- Example: - [Auth Feature](../features/auth.md) -->

## Context

[Why this work is needed]

## Approach

[High-level approach and key decisions]

## Progress Log

### ${TODAY}

- Started: ${description}

## Files Changed

<!-- Track significant file changes -->

## Next Steps

- [ ] [First task]

## Open Questions

<!-- Unresolved questions -->
PLANEOF

    print_success "Created: $filepath"
    
    # Add row to index
    if has_marker_pair "$index_file" "$PLAN_ROWS_START" "$PLAN_ROWS_END"; then
        local row="| [${name}](${filename}) | In Progress | ${description} |"
        insert_before_marker "$index_file" "$PLAN_ROWS_END" "$row"
        print_success "Added to index: $index_file"
    else
        print_error "Index missing row markers. Run 'docs-harness' to fix."
    fi
}

add_arch() {
    local name="$1"
    local description="$2"
    local slug
    slug=$(slugify "$name")
    local filename="${slug}.md"
    local filepath="docs/architecture/${filename}"
    local index_file="docs/architecture/_index.md"
    
    if [[ ! -d "docs/architecture" ]]; then
        print_error "docs/architecture/ not found. Run 'docs-harness' first."
        exit 1
    fi
    
    if [[ -f "$filepath" ]]; then
        print_error "Architecture doc already exists: $filepath"
        exit 1
    fi
    
    cat > "$filepath" << ARCHEOF
# ${name}

${description}

## Overview

[High-level description]

## Design Decisions

[Key decisions and rationale]

## Key Files

- \`path/to/file\` — [description]

## Dependencies

[What this depends on and what depends on it]
ARCHEOF

    print_success "Created: $filepath"
    
    if has_marker_pair "$index_file" "$ARCH_ROWS_START" "$ARCH_ROWS_END"; then
        local row="| [${name}](${filename}) | ${description} |"
        insert_before_marker "$index_file" "$ARCH_ROWS_END" "$row"
        print_success "Added to index: $index_file"
    else
        print_error "Index missing row markers. Run 'docs-harness' to fix."
    fi
}

add_feature() {
    local name="$1"
    local description="$2"
    local slug
    slug=$(slugify "$name")
    local filename="${slug}.md"
    local filepath="docs/features/${filename}"
    local index_file="docs/features/_index.md"
    
    if [[ ! -d "docs/features" ]]; then
        print_error "docs/features/ not found. Run 'docs-harness' first."
        exit 1
    fi
    
    if [[ -f "$filepath" ]]; then
        print_error "Feature doc already exists: $filepath"
        exit 1
    fi
    
    cat > "$filepath" << FEATEOF
# ${name}

${description}

## Overview

[What this does for users]

## Usage

[How to use it]

## Implementation

[Key implementation details]

## Key Files

- \`path/to/file\` — [description]
FEATEOF

    print_success "Created: $filepath"
    
    if has_marker_pair "$index_file" "$FEAT_ROWS_START" "$FEAT_ROWS_END"; then
        local row="| [${name}](${filename}) | Done | ${description} |"
        insert_before_marker "$index_file" "$FEAT_ROWS_END" "$row"
        print_success "Added to index: $index_file"
    else
        print_error "Index missing row markers. Run 'docs-harness' to fix."
    fi
}

# ============================================================================
# Check Structure
# ============================================================================

check_structure() {
    local all_ok=true
    
    echo "Checking docs-harness structure..."
    echo ""
    
    # Check directories
    for dir in "docs/architecture" "docs/features" "docs/plans"; do
        if [[ -d "$dir" ]]; then
            print_success "Directory: $dir"
        else
            print_error "Missing: $dir"
            all_ok=false
        fi
    done
    
    # Check AGENTS.md with both markers
    if [[ -f "AGENTS.md" ]]; then
        if has_marker_pair "AGENTS.md" "$MARKER_START" "$MARKER_END"; then
            print_success "AGENTS.md (markers OK)"
        else
            print_error "AGENTS.md missing START or END marker"
            all_ok=false
        fi
    else
        print_error "Missing: AGENTS.md"
        all_ok=false
    fi
    
    # Check index files with row markers
    if [[ -f "docs/architecture/_index.md" ]]; then
        if has_marker_pair "docs/architecture/_index.md" "$ARCH_ROWS_START" "$ARCH_ROWS_END"; then
            print_success "docs/architecture/_index.md (markers OK)"
        else
            print_error "docs/architecture/_index.md missing row markers"
            all_ok=false
        fi
    else
        print_error "Missing: docs/architecture/_index.md"
        all_ok=false
    fi
    
    if [[ -f "docs/features/_index.md" ]]; then
        if has_marker_pair "docs/features/_index.md" "$FEAT_ROWS_START" "$FEAT_ROWS_END"; then
            print_success "docs/features/_index.md (markers OK)"
        else
            print_error "docs/features/_index.md missing row markers"
            all_ok=false
        fi
    else
        print_error "Missing: docs/features/_index.md"
        all_ok=false
    fi
    
    if [[ -f "docs/plans/_index.md" ]]; then
        if has_marker_pair "docs/plans/_index.md" "$PLAN_ROWS_START" "$PLAN_ROWS_END"; then
            print_success "docs/plans/_index.md (markers OK)"
        else
            print_error "docs/plans/_index.md missing row markers"
            all_ok=false
        fi
    else
        print_error "Missing: docs/plans/_index.md"
        all_ok=false
    fi
    
    echo ""
    if $all_ok; then
        echo -e "${GREEN}All checks passed!${NC}"
        return 0
    else
        echo -e "${RED}Run 'docs-harness' to fix.${NC}"
        return 1
    fi
}

# ============================================================================
# Scaffold / Sync
# ============================================================================

scaffold() {
    require_repo_root
    
    echo "docs-harness: syncing documentation structure..."
    echo ""
    
    # Create directories
    for dir in "docs/architecture" "docs/features" "docs/plans"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "Created: $dir"
        fi
    done
    
    # Sync index files (preserves rows)
    sync_index_file "docs/architecture/_index.md" "$ARCH_INDEX_TEMPLATE" "$ARCH_ROWS_START" "$ARCH_ROWS_END"
    sync_index_file "docs/features/_index.md" "$FEAT_INDEX_TEMPLATE" "$FEAT_ROWS_START" "$FEAT_ROWS_END"
    sync_index_file "docs/plans/_index.md" "$PLAN_INDEX_TEMPLATE" "$PLAN_ROWS_START" "$PLAN_ROWS_END"
    
    # Sync AGENTS.md
    sync_agents_md
    
    echo ""
    echo -e "${GREEN}Done!${NC}"
}

# ============================================================================
# Help & Utilities
# ============================================================================

show_help() {
    cat << 'HELPEOF'
docs-harness - Documentation scaffolding for AI agents

USAGE
    docs-harness                        Scaffold/sync docs structure
    docs-harness add-plan NAME DESC     Add a plan
    docs-harness add-arch NAME DESC     Add architecture doc
    docs-harness add-feature NAME DESC  Add feature doc
    docs-harness --check                Validate structure and markers
    docs-harness --print-agents         Print canonical AGENTS block
    docs-harness --help                 Show this help
    docs-harness --version              Show version

INSTALL
    curl -fsSL https://raw.githubusercontent.com/melnikov-s/docs-harness/main/install.sh | bash

SYNC BEHAVIOR
    Running 'docs-harness' is safe to repeat. It:
    - Creates missing directories and files
    - Updates managed content (between markers)
    - Preserves user-added rows in index tables
    - Never deletes content outside markers

HELPEOF
}

print_agents_block() {
    printf '%s\n' "${MARKER_START}"
    printf '%s\n' "${AGENTS_HARNESS_CONTENT}"
    printf '%s\n' "${MARKER_END}"
}

# ============================================================================
# Main
# ============================================================================

main() {
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --version|-v)
            echo "docs-harness $VERSION"
            ;;
        --check)
            require_repo_root
            check_structure
            ;;
        --print-agents)
            print_agents_block
            ;;
        add-plan)
            require_repo_root
            [[ -z "${2:-}" || -z "${3:-}" ]] && { echo "Usage: docs-harness add-plan \"Name\" \"Description\""; exit 1; }
            add_plan "$2" "$3"
            ;;
        add-arch)
            require_repo_root
            [[ -z "${2:-}" || -z "${3:-}" ]] && { echo "Usage: docs-harness add-arch \"Name\" \"Description\""; exit 1; }
            add_arch "$2" "$3"
            ;;
        add-feature)
            require_repo_root
            [[ -z "${2:-}" || -z "${3:-}" ]] && { echo "Usage: docs-harness add-feature \"Name\" \"Description\""; exit 1; }
            add_feature "$2" "$3"
            ;;
        "")
            scaffold
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run 'docs-harness --help' for usage"
            exit 1
            ;;
    esac
}

main "$@"
