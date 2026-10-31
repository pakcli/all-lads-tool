#!/usr/bin/env bash
# ==============================================================================
# Git Reflog Parsing and Surgical Recovery Module
# Module: script/gitbash/module/git-reflog.sh
# ==============================================================================

get_reflog_commits() {
    local dir="$1"
    local max_count="${2:-15}"
    git -C "$dir" reflog -n "$max_count" --pretty=format:"%h|%gd|%cr|%s" 2>/dev/null
}

restore_reflog_file() {
    local dir="$1"
    local commit_hash="$2"
    local file_path="$3"
    git -C "$dir" checkout "$commit_hash" -- "$file_path" 2>/dev/null
}
