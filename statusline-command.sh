#!/bin/bash
# Claude Code status line - robbyrussell theme style
# Reads JSON input from stdin and outputs a formatted status line

input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Get current directory name (like \W in PS1)
if [ -n "$cwd" ]; then
    current_dir=$(basename "$cwd")
else
    current_dir="~"
fi

# Get git branch and status
git_branch=""
git_dirty=""
if [ -n "$cwd" ] && [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" describe --tags --exact-match 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    if [ -n "$git_branch" ]; then
        # Check if dirty
        if ! git -C "$cwd" diff --quiet --ignore-submodules 2>/dev/null || ! git -C "$cwd" diff --cached --quiet --ignore-submodules 2>/dev/null; then
            git_dirty="✗"
        else
            git_dirty="✔"
        fi
    fi
fi

# Build status line components with robbyrussell-style colors
# Green arrow for success/clean, can be customized
arrow_color="\033[36m"  # Cyan arrow (robbyrussell style)
reset="\033[0m"

# Cyan for directory
dir_color="\033[36m"

# Green for clean git, yellow for dirty
git_clean_color="\033[32m"
git_dirty_color="\033[33m"
git_branch_color="\033[34m"

# Build output
output=""

# Arrow (➜) - cyan color like robbyrussell
output="${output}${arrow_color}➜${reset} "

# Current directory - cyan
output="${output}${dir_color}${current_dir}${reset}"

# Git info if available
if [ -n "$git_branch" ]; then
    output="${output} ${git_branch_color}git:(${reset}"
    if [ "$git_dirty" = "✗" ]; then
        output="${output}${git_dirty_color}${git_branch}${reset}"
    else
        output="${output}${git_clean_color}${git_branch}${reset}"
    fi
    output="${output}${git_branch_color})${reset}"
    if [ "$git_dirty" = "✗" ]; then
        output="${output} ${git_dirty_color}✗${reset}"
    else
        output="${output} ${git_clean_color}✔${reset}"
    fi
fi

# Model info (Claude Code specific)
if [ -n "$model" ]; then
    output="${output} \033[90m[${model}]${reset}"
fi

# Context remaining percentage
if [ -n "$remaining" ] && [ "$remaining" != "null" ]; then
    if [ "$remaining" -lt 20 ]; then
        output="${output} \033[31m${remaining}%${reset}"
    elif [ "$remaining" -lt 50 ]; then
        output="${output} \033[33m${remaining}%${reset}"
    else
        output="${output} \033[32m${remaining}%${reset}"
    fi
fi

printf "%b" "$output"
