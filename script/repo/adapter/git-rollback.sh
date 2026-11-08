#!/usr/bin/env bash
# ==============================================================================
# Git Rollback & Soft Reset Adapter (POSIX Shell, Context: Repo Adapter)
# Script: script/repo/adapter/git-rollback.sh
# ==============================================================================

get_commit_checkpoints() {
    local dir="$1"
    local count="${2:-10}"
    git -C "$dir" log -n "$count" --pretty=format:"%h|%H|%s|%ar|%an" 2>/dev/null
}

resolve_checkpoint_hash() {
    local dir="$1"
    local commit_id="$2"
    git -C "$dir" rev-parse --verify "${commit_id}^{commit}" >/dev/null 2>&1 || return 1
    local full_hash
    full_hash=$(git -C "$dir" rev-parse "$commit_id" 2>/dev/null)
    echo "$full_hash"
}

get_commit_diff_count() {
    local dir="$1"
    local target_hash="$2"
    git -C "$dir" rev-list --count "${target_hash}..HEAD" 2>/dev/null || echo 0
}

invoke_soft_rollback() {
    local dir="$1"
    local target_hash="$2"
    git -C "$dir" reset --soft "$target_hash"
}

invoke_force_push_lease() {
    local dir="$1"
    local branch="$2"
    local remote="${3:-origin}"
    git -C "$dir" push --force-with-lease "$remote" "$branch"
}
