#!/bin/bash

# Sync Claude Code assets to GitHub Copilot / VS Code format
# - Agents: ~/.claude/agents/*.md -> .github/agents/*.agent.md
# - Skills: ~/.claude/skills/*/ -> ~/Library/.../prompts/{skill-name}.prompt.md (stub files)
# - Prompts: ~/.claude/commands/*/*.md -> ~/Library/.../prompts/{folder}-{name}.prompt.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# =============================================================================
# Sync Agents
# =============================================================================
sync_agents() {
    local source_dir="$HOME/.claude/agents"
    local target_dir="$PROJECT_ROOT/.github/agents"

    if [[ ! -d "$source_dir" ]]; then
        echo "Warning: Agents source directory not found: $source_dir"
        return
    fi

    mkdir -p "$target_dir"

    echo "Syncing agents..."
    echo "  Source: $source_dir"
    echo "  Target: $target_dir"
    echo ""

    local created=0 updated=0 skipped=0

    for source_file in "$source_dir"/*.md; do
        [[ -f "$source_file" ]] || continue

        local name=$(basename "$source_file" .md)
        local target_file="$target_dir/${name}.agent.md"

        if [[ -L "$target_file" ]]; then
            local current_target=$(readlink "$target_file")
            if [[ "$current_target" == "$source_file" ]]; then
                printf "  ${YELLOW}○${NC} ${name}.agent.md (unchanged)\n"
                ((skipped++))
            else
                rm "$target_file"
                ln -s "$source_file" "$target_file"
                printf "  ${GREEN}↻${NC} ${name}.agent.md (updated)\n"
                ((updated++))
            fi
        elif [[ -e "$target_file" ]]; then
            printf "  ${YELLOW}!${NC} ${name}.agent.md (regular file exists, skipping)\n"
            ((skipped++))
        else
            ln -s "$source_file" "$target_file"
            printf "  ${GREEN}+${NC} ${name}.agent.md\n"
            ((created++))
        fi
    done

    echo ""
    echo "  Agents: $created created, $updated updated, $skipped unchanged"
}

# =============================================================================
# Sync Skills (Skills -> VS Code Prompts as stubs)
# =============================================================================
sync_skills() {
    local source_dir="$HOME/.claude/skills"
    local target_dir="$HOME/Library/Application Support/Code/User/prompts"

    if [[ ! -d "$source_dir" ]]; then
        echo "Warning: Skills source directory not found: $source_dir"
        return
    fi

    mkdir -p "$target_dir"

    echo "Syncing skills..."
    echo "  Source: $source_dir"
    echo "  Target: $target_dir"
    echo ""

    local created=0 updated=0 skipped=0

    for skill_dir in "$source_dir"/*/; do
        [[ -d "$skill_dir" ]] || continue

        local skill_name=$(basename "$skill_dir")
        [[ "$skill_name" == .* ]] && continue

        local target_file="$target_dir/${skill_name}.prompt.md"
        local stub_content="---
description: Run skill ${skill_name}
---

Run skill: ${skill_name}
Context (optional): \$ARGUMENTS"

        if [[ -f "$target_file" ]]; then
            local existing_content=$(cat "$target_file")
            if [[ "$existing_content" == "$stub_content" ]]; then
                printf "  ${YELLOW}○${NC} ${skill_name}.prompt.md (unchanged)\n"
                ((skipped++))
            else
                echo "$stub_content" > "$target_file"
                printf "  ${GREEN}↻${NC} ${skill_name}.prompt.md (updated)\n"
                ((updated++))
            fi
        else
            echo "$stub_content" > "$target_file"
            printf "  ${GREEN}+${NC} ${skill_name}.prompt.md\n"
            ((created++))
        fi
    done

    echo ""
    echo "  Skills: $created created, $updated updated, $skipped unchanged"
}

# =============================================================================
# Sync Prompts (Commands -> VS Code Prompts)
# =============================================================================
sync_prompts() {
    local source_dir="$HOME/.claude/commands"
    local target_dir="$HOME/Library/Application Support/Code/User/prompts"

    if [[ ! -d "$source_dir" ]]; then
        echo "Warning: Commands source directory not found: $source_dir"
        return
    fi

    mkdir -p "$target_dir"

    echo ""
    echo "Syncing prompts..."
    echo "  Source: $source_dir"
    echo "  Target: $target_dir"
    echo ""

    local created=0 updated=0 skipped=0

    # Find all .md files in subdirectories
    # Transform: commands/{folder}/{name}.md -> prompts/{folder}-{name}.prompt.md
    for subfolder in "$source_dir"/*/; do
        [[ -d "$subfolder" ]] || continue

        local folder_name=$(basename "$subfolder")

        for source_file in "$subfolder"*.md; do
            [[ -f "$source_file" ]] || continue

            local file_name=$(basename "$source_file" .md)
            local target_name="${folder_name}-${file_name}.prompt.md"
            local target_file="$target_dir/$target_name"

            if [[ -L "$target_file" ]]; then
                local current_target=$(readlink "$target_file")
                if [[ "$current_target" == "$source_file" ]]; then
                    printf "  ${YELLOW}○${NC} $target_name (unchanged)\n"
                    ((skipped++))
                else
                    rm "$target_file"
                    ln -s "$source_file" "$target_file"
                    printf "  ${GREEN}↻${NC} $target_name (updated)\n"
                    ((updated++))
                fi
            elif [[ -e "$target_file" ]]; then
                printf "  ${YELLOW}!${NC} $target_name (regular file exists, skipping)\n"
                ((skipped++))
            else
                ln -s "$source_file" "$target_file"
                printf "  ${GREEN}+${NC} $target_name\n"
                ((created++))
            fi
        done
    done

    echo ""
    echo "  Prompts: $created created, $updated updated, $skipped unchanged"
}

# =============================================================================
# Main
# =============================================================================
echo "========================================"
echo "Syncing Claude Code -> GitHub Copilot"
echo "========================================"
echo ""

sync_agents
sync_skills
sync_prompts

echo ""
echo "========================================"
echo "Sync complete!"
echo "========================================"
