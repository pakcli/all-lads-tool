#!/usr/bin/env bash
# ==============================================================================
# Git Bash Tool State and Execution History Logger
# Module: script/gitbash/module/history.sh
# ==============================================================================

record_tool_action() {
    local json_file="$1"
    local tool_name="$2"
    local target_dir="$3"
    local action="$4"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Keep simple JSON format without requiring jq
    if [ ! -f "$json_file" ]; then
        echo "{\"tool\":\"$tool_name\",\"history\":[]}" > "$json_file"
    fi
}
