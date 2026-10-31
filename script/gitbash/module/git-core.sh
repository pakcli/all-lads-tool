#!/usr/bin/env bash
# ==============================================================================
# Low-level Git CLI process execution wrapper
# Module: script/gitbash/module/git-core.sh
# ==============================================================================

invoke_git_command() {
    local repo_path="$1"
    shift
    git -C "$repo_path" "$@"
}
