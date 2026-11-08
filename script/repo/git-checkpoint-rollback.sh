#!/usr/bin/env bash
# ==============================================================================
# Interactive Git Checkpoint Rollback and Safe Reset (Git Bash Edition)
# Script: script/repo/git-checkpoint-rollback.sh
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPTER_DIR="${SCRIPT_DIR}/adapter"

if [ -f "${ADAPTER_DIR}/git-rollback.sh" ]; then
    . "${ADAPTER_DIR}/git-rollback.sh"
    . "${ADAPTER_DIR}/git-core.sh"
    . "${ADAPTER_DIR}/git-status.sh"
else
    echo "Error: Required adapter scripts not found in ${ADAPTER_DIR}" >&2
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
MAGENTA="\033[1;35m"
RESET="\033[0m"

echo ""
echo -e "${CYAN}==========================================================${RESET}"
echo -e "   ${YELLOW}GIT CHECKPOINT ROLLBACK (SOFT RESET - KEEP LOCAL WORK)${RESET}"
echo -e "${CYAN}==========================================================${RESET}"

if ! test_is_git_repo "$TARGET_DIR"; then
    echo -e "${RED}[ERROR] '${TARGET_DIR}' bukan repositori Git yang valid!${RESET}"
    exit 1
fi

branch=$(git -C "$TARGET_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
echo -e " Target Repo : ${GREEN}${TARGET_DIR}${RESET}"
echo -e " Branch Aktif: ${CYAN}${branch}${RESET}"
echo -e "\n${YELLOW}Daftar 10 Commit Terakhir:${RESET}"
echo -e "${GRAY}------------------------------------------------------------------------------${RESET}"

raw_logs=$(get_commit_checkpoints "$TARGET_DIR" 10)
if [ -z "$raw_logs" ]; then
    echo -e "${RED}Tidak ada commit di repository ini.${RESET}"
    exit 1
fi

idx=1
declare -A commit_map
while IFS='|' read -r short_h full_h subj time author; do
    commit_map["$idx"]="$full_h"
    commit_map["$short_h"]="$full_h"
    commit_map["$full_h"]="$full_h"

    if [ "$idx" -eq 1 ]; then
        printf " [ %2d ] ${RED}%-9s${RESET} - ${WHITE}\"%s\"${RESET} ${YELLOW}(HEAD Saat Ini)${RESET}\n" "$idx" "$short_h" "$subj"
    else
        printf " [ %2d ] ${GREEN}%-9s${RESET} - ${WHITE}\"%s\"${RESET} ${CYAN}(%s)${RESET}\n" "$idx" "$short_h" "$subj" "$time"
    fi
    idx=$((idx + 1))
done <<< "$raw_logs"
echo -e "${GRAY}------------------------------------------------------------------------------${RESET}\n"

read -rp "Pilih nomor commit target [1-$((idx - 1)) atau Hash, 'q' untuk batal]: " user_choice
user_choice=$(echo "$user_choice" | tr -d ' "')

if [ -z "$user_choice" ] || [ "$user_choice" = "q" ]; then
    echo -e "\n${GRAY}[BATAL] Rollback dibatalkan.${RESET}\n"
    exit 0
fi

target_full_hash="${commit_map[$user_choice]}"
if [ -z "$target_full_hash" ]; then
    target_full_hash="$user_choice"
fi

if ! git -C "$TARGET_DIR" rev-parse --verify "${target_full_hash}^{commit}" >/dev/null 2>&1; then
    echo -e "\n${RED}[ERROR] Commit '${target_full_hash}' tidak valid atau tidak ditemukan!${RESET}\n"
    exit 1
fi

target_full_hash=$(git -C "$TARGET_DIR" rev-parse "$target_full_hash")
target_short_hash=$(git -C "$TARGET_DIR" rev-parse --short "$target_full_hash")
target_subj=$(git -C "$TARGET_DIR" log -1 --pretty=format:"%s" "$target_full_hash")
diff_count=$(get_commit_diff_count "$TARGET_DIR" "$target_full_hash")

if [ "$diff_count" -eq 0 ]; then
    echo -e "\n${YELLOW}[WARNING] Posisi repo sudah berada di commit tersebut (${target_short_hash}). Tidak ada yang perlu dimundurkan.${RESET}\n"
    exit 0
fi

echo ""
echo -e "${CYAN}==========================================================${RESET}"
echo -e "   ${YELLOW}GIT CHECKPOINT ROLLBACK PRE-FLIGHT OVERVIEW${RESET}"
echo -e "${CYAN}==========================================================${RESET}"
echo -e " Target Repo      : ${WHITE}${TARGET_DIR}${RESET}"
echo -e " Branch Aktif     : ${WHITE}${branch}${RESET}"
echo -e " Mundur ke Commit : ${GREEN}${target_short_hash} (\"${target_subj}\")${RESET}"
echo -e " Commit Dicopot   : ${RED}${diff_count} commit terbaru dari history${RESET}"
echo -e " Kodingan Lokal   : ${GREEN}100% AMAN (masuk ke Staging Area via reset --soft)${RESET}"
echo -e " Perintah Git     : ${GRAY}git reset --soft ${target_short_hash}${RESET}"
echo -e "${CYAN}==========================================================${RESET}\n"

read -rp "Lanjutkan proses mundur ini? (y/N): " confirm_step
if [[ ! "$confirm_step" =~ ^[Yy]$ ]]; then
    echo -e "\n${GRAY}[BATAL] Rollback dibatalkan.${RESET}\n"
    exit 0
fi

echo -e "\n${CYAN}[*] Menjalankan safe rollback...${RESET}"
if invoke_soft_rollback "$TARGET_DIR" "$target_full_hash"; then
    echo -e "${GREEN}[OK] LOKAL SELESAI: History lokal berhasil dimundurkan ke ${target_short_hash}.${RESET}"
    echo -e "     ${WHITE}Semua file kodingan tetap aman di Staging Area (index).${RESET}\n"
else
    echo -e "${RED}[ERROR] Gagal menjalankan soft rollback.${RESET}"
    exit 1
fi

read -rp "Force-push ke origin/${branch} dengan lease? (y/N) [Default: N]: " confirm_push
if [[ "$confirm_push" =~ ^[Yy]$ ]]; then
    echo -e "\n${CYAN}[*] Mengupdate remote origin/${branch}...${RESET}"
    if invoke_force_push_lease "$TARGET_DIR" "$branch" "origin"; then
        echo -e "${GREEN}[SEMPURNA] Remote GitHub dan Lokal sudah sama-sama berada di save-an target.${RESET}\n"
    else
        echo -e "${RED}[ERROR] Gagal push ke remote.${RESET}\n"
    fi
else
    echo -e "\n${YELLOW}[INFO] Remote belum diupdate. Untuk update manual:${RESET}"
    echo -e "       ${CYAN}git push --force-with-lease origin ${branch}${RESET}\n"
fi
