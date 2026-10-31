#!/usr/bin/env bash
# ==============================================================================
# Git Status & Repository Inspection Module
# Module: script/gitbash/module/git-status.sh
# ==============================================================================

test_is_git_repo() {
    local dir="$1"
    [ -d "$dir/.git" ] || git -C "$dir" rev-parse --git-dir >/dev/null 2>&1
}

get_git_branch() {
    local dir="$1"
    local branch
    branch=$(git -C "$dir" branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
        branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
        if [ -z "$branch" ]; then
            echo "empty"
        else
            echo "(detached: $branch)"
        fi
    else
        echo "$branch"
    fi
}

get_git_remote() {
    local dir="$1"
    local remote
    remote=$(git -C "$dir" remote -v 2>/dev/null | head -n 1 | awk '{print $1}')
    if [ -z "$remote" ]; then
        echo "None"
    else
        echo "$remote"
    fi
}

get_dirty_count() {
    local dir="$1"
    git -C "$dir" status -s 2>/dev/null | wc -l | tr -d ' '
}
