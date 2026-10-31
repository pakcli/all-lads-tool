#!/usr/bin/env bash
# ==============================================================================
# Git Submodule Automation Engine
# Module: script/gitbash/module/git-submodule.sh
# ==============================================================================

get_submodule_list() {
    local dir="$1"
    git -C "$dir" submodule status 2>/dev/null
}

add_submodule_item() {
    local dir="$1"
    local url="$2"
    local dest="$3"
    git -C "$dir" submodule add "$url" "$dest" && \
    git -C "$dir" submodule update --init --recursive "$dest"
}

remove_submodule_item() {
    local dir="$1"
    local sub_path="$2"
    git -C "$dir" submodule deinit -f -- "$sub_path" && \
    git -C "$dir" rm -f "$sub_path" && \
    rm -rf "$dir/.git/modules/$sub_path"
}

sync_submodule_item() {
    local dir="$1"
    local sub_path="${2:-}"
    if [ -n "$sub_path" ]; then
        git -C "$dir" submodule update --init --recursive -- "$sub_path"
    else
        git -C "$dir" submodule update --init --recursive
    fi
}
