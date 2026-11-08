#!/usr/bin/env bash
# ==============================================================================
# Universal Git Manager & Recovery Tool (Git Bash Edition, Context: Repo)
# Script: script/repo/git-manage.sh
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPTER_DIR="${SCRIPT_DIR}/adapter"

# Wire up internal adapter modules
if [ -d "$ADAPTER_DIR" ]; then
    . "${ADAPTER_DIR}/git-core.sh"
    . "${ADAPTER_DIR}/git-status.sh"
    . "${ADAPTER_DIR}/git-reflog.sh"
    . "${ADAPTER_DIR}/git-submodule.sh"
    . "${ADAPTER_DIR}/history.sh"
else
    echo "Error: Required Git Bash adapter directory not found: $ADAPTER_DIR" >&2
    exit 1
fi

REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." 2>/dev/null && pwd)"
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
        git -C "$dir" restore . 2>/dev/null
        git -C "$dir" clean -fd 2>/dev/null
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

invoke_assign_git_action() {
    local dir="$1"
    echo -e "\n${CYAN}=== [5] ASSIGN GIT (INITIALIZE REPOSITORY) ===${RESET}"
    if test_is_git_repo "$dir"; then
        echo -e "${YELLOW}Directory '${dir}' is already a Git repository.${RESET}"
        read -rp "Re-initialize? [y/N]: " reinit
        if [[ ! "$reinit" =~ ^[Yy]$ ]]; then return; fi
    else
        git -C "$dir" init -b main 2>/dev/null || git -C "$dir" init
        echo -e "${GREEN}[OK] Git repository initialized.${RESET}"
    fi

    local gi="${dir}/.gitignore"
    if [ ! -f "$gi" ]; then
        cat << 'EOF' > "$gi"
# Dependencies
node_modules/
vendor/

# Logs & Temp
*.log
.DS_Store
Thumbs.db
*.bak
*.tmp

# Builds
dist/
build/
EOF
        echo -e "${GREEN}[OK] Created default .gitignore${RESET}"
    fi

    read -rp "Enter Remote Git URL (or press Enter to skip): " rem_url
    if [ -n "$rem_url" ]; then
        git -C "$dir" remote add origin "$rem_url" 2>/dev/null || git -C "$dir" remote set-url origin "$rem_url"
        echo -e "${GREEN}[OK] Remote origin configured.${RESET}"
    fi

    read -rp "Create initial commit? [Y/n]: " do_c
    if [[ ! "$do_c" =~ ^[Nn]$ ]]; then
        git -C "$dir" add -A
        git -C "$dir" commit -m "chore: initial repository setup" 2>/dev/null
        echo -e "${GREEN}[OK] Initial commit created.${RESET}"
    fi
}

invoke_remove_git_action() {
    local dir="$1"
    echo -e "\n${RED}=== [6] REMOVE GIT (SAFE UNLINK) ===${RESET}"
    local git_dir="${dir}/.git"
    if [ ! -d "$git_dir" ]; then
        echo -e "${YELLOW}No .git folder found in '${dir}'. Nothing to remove.${RESET}"
        return
    fi

    echo -e "${RED}[SAFETY WARNING]: This will remove all Git history and branches from '${dir}'. Project files will be untouched.${RESET}"
    read -rp "Type 'REMOVE' to confirm: " confirm
    if [ "$confirm" != "REMOVE" ]; then
        echo -e "${GRAY}Removal cancelled.${RESET}"
        return
    fi

    chmod -R u+w "$git_dir" 2>/dev/null
    rm -rf "$git_dir"
    if [ ! -d "$git_dir" ]; then
        echo -e "${GREEN}[SUCCESS] Git tracking completely removed from '${dir}'.${RESET}"
    else
        echo -e "${RED}[ERROR] Failed to completely remove .git folder.${RESET}"
    fi
}

invoke_clone_action() {
    local dir="$1"
    echo -e "\n${CYAN}=== [7] CLONE REPOSITORY ===${RESET}"
    read -rp "Enter Remote Git URL: " clone_url
    if [ -z "$clone_url" ]; then
        echo -e "${YELLOW}URL cannot be empty.${RESET}"
        return
    fi

    local repo_name
    repo_name=$(basename "$clone_url" .git)
    local target_dest="${dir}/${repo_name}"

    read -rp "Clone into '${target_dest}'? [Y/n]: " do_cl
    if [[ "$do_cl" =~ ^[Nn]$ ]]; then
        read -rp "Enter custom destination directory: " target_dest
    fi

    if [ -z "$target_dest" ]; then
        echo -e "${YELLOW}Aborted.${RESET}"
        return
    fi

    read -rp "Shallow clone (--depth 1)? [y/N]: " is_shallow
    local depth_flag=""
    if [[ "$is_shallow" =~ ^[Yy]$ ]]; then
        depth_flag="--depth 1"
    fi

    echo -e "${CYAN}Executing: git clone ${depth_flag} ${clone_url} ${target_dest}${RESET}"
    git clone $depth_flag "$clone_url" "$target_dest"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] Cloned into ${target_dest}${RESET}"
    else
        echo -e "${RED}[ERROR] Git clone failed.${RESET}"
    fi
}

invoke_worktree_action() {
    local dir="$1"
    echo -e "\n${CYAN}=== [8] WORKTREE MANAGEMENT ===${RESET}"
    echo -e "${GREEN}Current Worktrees:${RESET}"
    git -C "$dir" worktree list
    echo ""
    echo "  [1] Add Worktree"
    echo "  [2] Remove Worktree"
    echo "  [3] Prune Worktrees"
    echo "  [4] Return"
    read -rp "Select option [1-4]: " wt_opt

    case "$wt_opt" in
        1)
            read -rp "Enter branch name: " wt_br
            read -rp "Enter worktree path: " wt_p
            if [ -n "$wt_br" ] && [ -n "$wt_p" ]; then
                git -C "$dir" worktree add "$wt_p" "$wt_br" 2>/dev/null || git -C "$dir" worktree add -b "$wt_br" "$wt_p"
                echo -e "${GREEN}[OK] Worktree added.${RESET}"
            fi
            ;;
        2)
            read -rp "Enter worktree path to remove: " wt_rem
            if [ -n "$wt_rem" ]; then
                git -C "$dir" worktree remove "$wt_rem"
                echo -e "${GREEN}[OK] Worktree removed.${RESET}"
            fi
            ;;
        3)
            git -C "$dir" worktree prune -v
            echo -e "${GREEN}[OK] Worktrees pruned.${RESET}"
            ;;
        *)
            ;;
    esac
}

invoke_custom_shell_action() {
    local dir="$1"
    echo -e "\n${CYAN}=== [9] CUSTOM SHELL / SCRIPT RUNNER ===${RESET}"
    echo -e "${GRAY}Target: ${dir}. Type commands or 'q' to return.${RESET}"
    while true; do
        read -rp "Shell (${dir}) > " cmd
        if [ -z "$cmd" ] || [ "$cmd" = "q" ]; then break; fi
        (cd "$dir" && eval "$cmd")
    done
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

show_help_guide() {
    echo -e "\n${CYAN}=== [h] GIT MANAGER HELP & SHORTCUTS ===${RESET}"
    cat << 'EOF'
Universal Git Manager (git-manage.sh, Context: Repo)

COMMAND MATRIX (-1 to 9, 11):
  [-1] Discard All Changes : Rollback all uncommitted changes (restore + clean)
  [ 0] Status              : Live dashboard showing active branch, remotes, dirty files, log
  [ 1] Recover             : Restores detached or lost commits from git reflog
  [ 2] Commit              : Status preview, staging, and commit message helper
  [ 3] Push                : Pushes current branch to remote with upstream tracking
  [ 4] Pull / Sync         : Smart pull with linear rebase
  [ 5] Assign Git          : Initializes Git repository, sets remote, creates .gitignore
  [ 6] Remove Git          : Safe .git unlink with attribute unlock and confirmation
  [ 7] Clone               : Clones external repository into designated target directory
  [ 8] Worktree            : Manages git worktrees (list, add, remove, prune)
  [ 9] Custom Shell        : Interactive shell inside target directory
  [ 11] Submodule Hub      : Interactive Git Submodule Hub (list, add, remove, sync)

FOOTER CONTROLS:
  [ h] Help                : Display this guide
  [ t] Switch Target       : Change working target directory
  [ q] Quit                : Exit tool
EOF
    echo ""
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
        status_line="NOT A GIT REPO (Use [5] Assign Git or [7] Clone)"
        status_color="$YELLOW"
    fi

    echo ""
    echo -e "${CYAN}========================================================================${RESET}"
    echo -e "   ${YELLOW}[GIT BASH] UNIVERSAL GIT MANAGER (CONTEXT: REPO)  ::  all-lads-tool${RESET}"
    echo -e "${CYAN}========================================================================${RESET}"
    echo -e " Target Directory : ${WHITE}${TARGET_DIR}${RESET}"
    echo -e " Git Status       : ${status_color}${status_line}${RESET}"
    echo -e " Mode             : ${GRAY}Modular (Connected to script/repo/adapter/*.sh)${RESET}"
    echo -e "${CYAN}========================================================================${RESET}"
    echo ""
    echo -e "  ${RED}[-1 ]  Discard All   : Rollback uncommitted changes safely${RESET}"
    echo -e "  ${WHITE}[ 0 ]  Status        : Dashboard (branch, remotes, status, recent log)${RESET}"
    echo -e "  ${YELLOW}[ 1 ]  Recover       : Reflog browser (adapter/git-reflog.sh)${RESET}"
    echo -e "  ${GREEN}[ 2 ]  Commit        : Git status staging & commit message${RESET}"
    echo -e "  ${GREEN}[ 3 ]  Push          : Push branch to remote with upstream tracking${RESET}"
    echo -e "  ${CYAN}[ 4 ]  Pull / Sync   : Smart pull (Rebase)${RESET}"
    echo -e "  ${CYAN}[ 5 ]  Assign Git    : Initialize repo (git init, remote, .gitignore)${RESET}"
    echo -e "  ${YELLOW}[ 6 ]  Remove Git    : Safe .git unlink with confirmation${RESET}"
    echo -e "  ${CYAN}[ 7 ]  Clone         : Clone repo from remote URL into target folder${RESET}"
    echo -e "  ${CYAN}[ 8 ]  Worktree      : Manage isolated branch worktrees (list/add/rm)${RESET}"
    echo -e "  ${CYAN}[ 9 ]  Custom Shell  : Custom command or script runner${RESET}"
    echo -e "  ${GREEN}[ 11]  Submodule     : Manage git submodules (adapter/git-submodule.sh)${RESET}"
    echo ""
    echo -e "${GRAY} ----------------------------------------------------------------------${RESET}"
    echo -e "  ${GRAY}[ h ]  Help          : Full Guide and shortcuts${RESET}"
    echo -e "  ${GRAY}[ t ]  Target Dir    : Change Target Project Directory${RESET}"
    echo -e "  ${GRAY}[ q ]  Quit          : Exit Git Manager${RESET}"
    echo -e "${CYAN}========================================================================${RESET}"

    read -rp "Select option [-1 to 9, 11, h, t, q] [Default: 0]: " choice
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
        "5")
            invoke_assign_git_action "$TARGET_DIR"
            read -rp "Press [Enter] to continue..."
            ;;
        "6")
            invoke_remove_git_action "$TARGET_DIR"
            read -rp "Press [Enter] to continue..."
            ;;
        "7")
            invoke_clone_action "$TARGET_DIR"
            read -rp "Press [Enter] to continue..."
            ;;
        "8")
            invoke_worktree_action "$TARGET_DIR"
            read -rp "Press [Enter] to continue..."
            ;;
        "9")
            invoke_custom_shell_action "$TARGET_DIR"
            ;;
        "11")
            invoke_submodule_hub "$TARGET_DIR"
            read -rp "Press [Enter] to continue..."
            ;;
        "h"|"H")
            show_help_guide
            read -rp "Press [Enter] to continue..."
            ;;
        "t"|"T")
            read -rp "Enter new target directory: " new_dir
            if [ -d "$new_dir" ]; then
                TARGET_DIR="$new_dir"
                echo -e "${GREEN}Target changed to: $TARGET_DIR${RESET}"
            else
                echo -e "${YELLOW}Directory does not exist.${RESET}"
            fi
            sleep 1
            ;;
        "q"|"Q")
            echo -e "${CYAN}Goodbye lads!${RESET}"
            break
            ;;
        *)
            echo -e "${YELLOW}Invalid option: '$choice'${RESET}"
            sleep 1
            ;;
    esac
done
