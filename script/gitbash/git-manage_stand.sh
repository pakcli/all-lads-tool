#!/usr/bin/env bash
# ==============================================================================
# Universal Git Manager & Recovery Tool (Git Bash Standalone Edition)
# Script: script/gitbash/git-manage_stand.sh
# Inlined Zero-Dependency Standalone Executable
# ==============================================================================

# ------------------------------------------------------------------------------
# INLINED MODULES (gitcore, gitstatus, reflog, submodule, history)
# ------------------------------------------------------------------------------
invoke_git_command() {
    local repo_path="$1"
    shift
    git -C "$repo_path" "$@"
}

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

record_tool_action() {
    local json_file="$1"
    local tool_name="$2"
    local target_dir="$3"
    local action="$4"
    if [ ! -f "$json_file" ]; then
        echo "{\"tool\":\"$tool_name\",\"history\":[]}" > "$json_file"
    fi
}

# ------------------------------------------------------------------------------
# MAIN APPLICATION LOGIC
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." 2>/dev/null && pwd)"
[ -z "$REPO_ROOT" ] && REPO_ROOT="$(pwd)"

TARGET_DIR="${1:-$REPO_ROOT}"
if [ ! -d "$TARGET_DIR" ]; then
    TARGET_DIR="$REPO_ROOT"
fi

# ANSI Colors
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
GRAY="\033[0;90m"
WHITE="\033[1;37m"
RESET="\033[0m"

invoke_commit_action() {
    local dir="$1"
    echo -e "\n${CYAN}=== [2] COMMIT ===${RESET}"
    local status_out
    status_out=$(git -C "$dir" status -s 2>/dev/null)
    if [ -z "$status_out" ]; then
        echo -e "${GREEN}Working tree is clean. Nothing to commit.${RESET}"
        return
    fi

    echo -e "${YELLOW}Current Status:${RESET}"
    echo "$status_out"

    echo -e "\n${CYAN}Staging Options:${RESET}"
    echo "  [1] Stage all changes (git add -A) [Default]"
    echo "  [2] Cancel"
    read -rp "Select staging option [Default: 1]: " stage_opt
    stage_opt="${stage_opt:-1}"

    if [ "$stage_opt" != "1" ]; then
        echo -e "${GRAY}Commit cancelled.${RESET}"
        return
    fi

    git -C "$dir" add -A
    echo -e "${GREEN}[OK] All changes staged.${RESET}"

    read -rp "Enter commit message: " msg
    if [ -z "$msg" ]; then
        echo -e "${RED}Commit message cannot be empty. Aborted.${RESET}"
        return
    fi

    git -C "$dir" commit -m "$msg"
    echo -e "${GREEN}[OK] Commit created successfully!${RESET}"
}

invoke_push_action() {
    local dir="$1"
    echo -e "\n${CYAN}=== [3] PUSH ===${RESET}"
    local branch
    branch=$(git -C "$dir" branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
        echo -e "${RED}Cannot push in detached HEAD state.${RESET}"
        return
    fi
    echo -e "${CYAN}Pushing branch '${branch}' to origin...${RESET}"
    git -C "$dir" push --set-upstream origin "$branch"
    echo -e "${GREEN}[OK] Push executed.${RESET}"
}

invoke_pull_action() {
    local dir="$1"
    echo -e "\n${CYAN}=== [4] PULL / SYNC ===${RESET}"
    echo -e "${CYAN}Pulling updates with linear rebase...${RESET}"
    git -C "$dir" pull --rebase
    echo -e "${GREEN}[OK] Sync complete.${RESET}"
}

invoke_discard_action() {
    local dir="$1"
    echo -e "\n${RED}=== [-1] DISCARD ALL CHANGES ===${RESET}"
    read -rp "Type 'DISCARD' to confirm rolling back uncommitted changes: " confirm
    if [ "$confirm" = "DISCARD" ]; then
        git -C "$dir" restore .
        git -C "$dir" clean -fd
        echo -e "${GREEN}[OK] Working tree clean.${RESET}"
    else
        echo -e "${GRAY}Discard cancelled.${RESET}"
    fi
}

invoke_reflog_browser() {
    local dir="$1"
    echo -e "\n${CYAN}=== [1] REFLOG BROWSER & COMMIT RECOVERY ===${RESET}"
    local raw_logs
    raw_logs=$(get_reflog_commits "$dir" 15)
    if [ -z "$raw_logs" ]; then
        echo -e "${YELLOW}No reflog entries found.${RESET}"
        return
    fi

    echo -e "${WHITE}Recent Reflog Timeline:${RESET}"
    echo "$raw_logs" | while IFS='|' read -r hash ref time msg; do
        echo -e "  ${YELLOW}${hash}${RESET} (${GRAY}${time}${RESET}) ${ref} : ${WHITE}${msg}${RESET}"
    done

    echo ""
    read -rp "Enter commit hash to inspect / checkout (or [Enter] to return): " chosen_hash
    if [ -n "$chosen_hash" ]; then
        git -C "$dir" show --stat "$chosen_hash"
        read -rp "Checkout this commit in detached mode? [y/N]: " do_co
        if [[ "$do_co" =~ ^[Yy]$ ]]; then
            git -C "$dir" checkout "$chosen_hash"
        fi
    fi
}

invoke_submodule_hub() {
    local dir="$1"
    echo -e "\n${CYAN}=== [11] SUBMODULE HUB ===${RESET}"
    local subs
    subs=$(get_submodule_list "$dir")
    if [ -z "$subs" ]; then
        echo -e "${YELLOW}No submodules found in repository.${RESET}"
    else
        echo -e "${WHITE}Registered Submodules:${RESET}"
        echo "$subs"
    fi

    echo ""
    echo "  [1] Add Submodule"
    echo "  [2] Sync / Update Submodules"
    echo "  [3] Remove Submodule"
    echo "  [b] Back to Main Menu"
    read -rp "Select submodule action: " sub_act

    case "$sub_act" in
        1)
            read -rp "Enter repository Git URL: " sub_url
            read -rp "Enter destination path: " sub_dest
            if [ -n "$sub_url" ] && [ -n "$sub_dest" ]; then
                add_submodule_item "$dir" "$sub_url" "$sub_dest"
                echo -e "${GREEN}[OK] Submodule added.${RESET}"
            fi
            ;;
        2)
            sync_submodule_item "$dir"
            echo -e "${GREEN}[OK] Submodules synced.${RESET}"
            ;;
        3)
            read -rp "Enter submodule path to remove: " sub_rem
            if [ -n "$sub_rem" ]; then
                remove_submodule_item "$dir" "$sub_rem"
                echo -e "${GREEN}[OK] Submodule removed.${RESET}"
            fi
            ;;
        *)
            ;;
    esac
}

while true; do
    is_repo=$(test_is_git_repo "$TARGET_DIR" && echo "true" || echo "false")
    if [ "$is_repo" = "true" ]; then
        branch=$(get_git_branch "$TARGET_DIR")
        remote=$(get_git_remote "$TARGET_DIR")
        dirty=$(get_dirty_count "$TARGET_DIR")
        status_line="INITIALIZED (Branch: ${branch}) | Remote: ${remote} | Dirty Files: ${dirty}"
        status_color="$GREEN"
    else
        status_line="NOT A GIT REPO"
        status_color="$YELLOW"
    fi

    echo ""
    echo -e "${CYAN}========================================================================${RESET}"
    echo -e "   ${YELLOW}[GIT BASH] UNIVERSAL GIT MANAGER (STANDALONE)  ::  all-lads-tool${RESET}"
    echo -e "${CYAN}========================================================================${RESET}"
    echo -e " Target Directory : ${WHITE}${TARGET_DIR}${RESET}"
    echo -e " Git Status       : ${status_color}${status_line}${RESET}"
    echo -e " Mode             : ${GRAY}Standalone (_stand.sh zero-dependency executable)${RESET}"
    echo -e "${CYAN}========================================================================${RESET}"
    echo ""
    echo -e "  ${RED}[-1 ]  Discard All   : Rollback uncommitted changes safely${RESET}"
    echo -e "  ${WHITE}[ 0 ]  Status        : Dashboard (branch, remotes, status, recent log)${RESET}"
    echo -e "  ${YELLOW}[ 1 ]  Recover       : Reflog browser (module/git-reflog.sh)${RESET}"
    echo -e "  ${GREEN}[ 2 ]  Commit        : Git status staging & commit message${RESET}"
    echo -e "  ${GREEN}[ 3 ]  Push          : Push branch to remote with upstream tracking${RESET}"
    echo -e "  ${CYAN}[ 4 ]  Pull / Sync   : Smart pull (Rebase)${RESET}"
    echo -e "  ${GREEN}[ 11]  Submodule     : Manage git submodules (module/git-submodule.sh)${RESET}"
    echo ""
    echo -e "${GRAY} ----------------------------------------------------------------------${RESET}"
    echo -e "  ${GRAY}[ t ]  Target Dir    : Change Target Project Directory${RESET}"
    echo -e "  ${GRAY}[ q ]  Quit          : Exit Git Manager${RESET}"
    echo -e "${CYAN}========================================================================${RESET}"

    read -rp "Select option [-1, 0-4, 11, t, q] [Default: 0]: " choice
    choice="${choice:-0}"

    case "$choice" in
        "-1")
            invoke_discard_action "$TARGET_DIR"
            read -rp "Press [Enter] to continue..."
            ;;
        "0")
            echo -e "\n${CYAN}=== CURRENT GIT STATUS & LOG ===${RESET}"
            git -C "$TARGET_DIR" status -s
            echo ""
            git -C "$TARGET_DIR" log -n 5 --oneline
            read -rp "Press [Enter] to continue..."
            ;;
        "1")
            invoke_reflog_browser "$TARGET_DIR"
            read -rp "Press [Enter] to continue..."
            ;;
        "2")
            invoke_commit_action "$TARGET_DIR"
            read -rp "Press [Enter] to continue..."
            ;;
        "3")
            invoke_push_action "$TARGET_DIR"
            read -rp "Press [Enter] to continue..."
            ;;
        "4")
            invoke_pull_action "$TARGET_DIR"
            read -rp "Press [Enter] to continue..."
            ;;
        "11")
            invoke_submodule_hub "$TARGET_DIR"
            read -rp "Press [Enter] to continue..."
            ;;
        "t")
            read -rp "Enter new target directory: " new_dir
            if [ -d "$new_dir" ]; then
                TARGET_DIR="$new_dir"
                echo -e "${GREEN}Target changed to: $TARGET_DIR${RESET}"
            else
                echo -e "${YELLOW}Directory does not exist.${RESET}"
            fi
            sleep 1
            ;;
        "q")
            echo -e "${CYAN}Goodbye!${RESET}"
            break
            ;;
        *)
            echo -e "${YELLOW}Invalid option: '$choice'${RESET}"
            sleep 1
            ;;
    esac
done
