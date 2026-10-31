#!/usr/bin/env bash
# ==============================================================================
# SH_CHECK-BATTERY.SH
# Cross-Platform Battery Health & Telemetry Detail Viewer.
# Supports: Git Bash (Windows), WSL, Native Linux, and macOS.
# Complies with Rule #002 (Zero Horizontal Scroll) and Rule #004 (Naming).
# ==============================================================================

set -euo pipefail

# ANSI Colors
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
WHITE="\033[1;37m"
GRAY="\033[0;90m"
RESET="\033[0m"

clear 2>/dev/null || true
echo -e "${CYAN}========================================================================${RESET}"
echo -e "${GREEN}   CROSS-PLATFORM BATTERY TELEMETRY & DETAIL  ::  all-lads-tool${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# Environment Detection
OS_ENV="unknown"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || -n "${MINGW_CHOST:-}" || -n "${WINDIR:-}" ]]; then
    OS_ENV="git-bash"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_ENV="macos"
elif [ -d "/sys/class/power_supply" ]; then
    OS_ENV="linux"
else
    # Fallback check for Windows executables available
    if command -v powershell.exe >/dev/null 2>&1; then
        OS_ENV="git-bash"
    fi
fi

echo -e " Environment Detected : ${YELLOW}${OS_ENV}${RESET}"
echo -e "${CYAN}------------------------------------------------------------------------${RESET}"

render_bar() {
    local percent="${1:-0}"
    local bar_length=20
    local filled=$(( (percent * bar_length) / 100 ))
    local empty=$(( bar_length - filled ))
    local bar=""
    
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done

    local color="${GREEN}"
    if [ "$percent" -le 20 ]; then
        color="${RED}"
    elif [ "$percent" -le 50 ]; then
        color="${YELLOW}"
    fi

    echo -e "${color}[${bar}] ${percent}%${RESET}"
}

# --- 1. GIT BASH / WINDOWS IMPLEMENTATION ---
if [[ "$OS_ENV" == "git-bash" ]]; then
    echo -e "${WHITE} Querying Windows Battery Subsystem via CIM/WMI...${RESET}"
    echo ""

    BAT_DATA=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '
        $b = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $b) {
            Write-Output "NO_BATTERY"
            exit
        }

        $statusStr = switch ($b.BatteryStatus) {
            1 { "Discharging" }
            2 { "AC Power Connected (Unknown/Idle)" }
            3 { "Fully Charged" }
            4 { "Low" }
            5 { "Critical" }
            6 { "Charging" }
            7 { "Charging and High" }
            8 { "Charging and Low" }
            9 { "Charging and Critical" }
            11 { "Partially Charged" }
            default { "Active ($($b.BatteryStatus))" }
        }

        Write-Output "NAME=$($b.Name)"
        Write-Output "PERCENT=$($b.EstimatedChargeRemaining)"
        Write-Output "STATUS=$statusStr"
        Write-Output "VOLTAGE=$($b.DesignVoltage)"
        Write-Output "CHEMISTRY=$($b.Chemistry)"
        Write-Output "RUNTIME_MIN=$($b.EstimatedRunTime)"
    ' 2>/dev/null | tr -d '\r')

    if [[ "$BAT_DATA" == *"NO_BATTERY"* || -z "$BAT_DATA" ]]; then
        echo -e "${YELLOW} [i] No battery detected (Desktop PC or Virtual Machine).${RESET}"
    else
        BAT_NAME=$(echo "$BAT_DATA" | grep '^NAME=' | cut -d= -f2- || echo "Unknown")
        BAT_PERCENT=$(echo "$BAT_DATA" | grep '^PERCENT=' | cut -d= -f2- || echo "0")
        BAT_STATUS=$(echo "$BAT_DATA" | grep '^STATUS=' | cut -d= -f2- || echo "Unknown")
        BAT_VOLT=$(echo "$BAT_DATA" | grep '^VOLTAGE=' | cut -d= -f2- || echo "N/A")
        BAT_CHEM=$(echo "$BAT_DATA" | grep '^CHEMISTRY=' | cut -d= -f2- || echo "N/A")
        BAT_RUN=$(echo "$BAT_DATA" | grep '^RUNTIME_MIN=' | cut -d= -f2- || echo "N/A")

        echo -e " Battery Name     : ${WHITE}${BAT_NAME}${RESET}"
        echo -e " Charge Level     : $(render_bar "$BAT_PERCENT")"
        echo -e " Power Status     : ${CYAN}${BAT_STATUS}${RESET}"
        echo -e " Design Voltage   : ${WHITE}${BAT_VOLT} mV${RESET}"
        if [ "$BAT_CHEM" != "N/A" ] && [ -n "$BAT_CHEM" ]; then
            echo -e " Chemistry        : ${WHITE}${BAT_CHEM}${RESET}"
        fi
        if [ "$BAT_RUN" != "N/A" ] && [ "$BAT_RUN" != "71582788" ] && [ -n "$BAT_RUN" ]; then
            echo -e " Est. Runtime     : ${WHITE}${BAT_RUN} minutes${RESET}"
        fi
    fi

# --- 2. LINUX / WSL IMPLEMENTATION ---
elif [[ "$OS_ENV" == "linux" ]]; then
    BAT_DIR=""
    for b in /sys/class/power_supply/BAT* /sys/class/power_supply/battery; do
        if [ -d "$b" ]; then
            BAT_DIR="$b"
            break
        fi
    done

    if [ -z "$BAT_DIR" ]; then
        echo -e "${YELLOW} [i] No battery found in /sys/class/power_supply/ (Desktop or WSL).${RESET}"
    else
        CAPACITY=$(cat "$BAT_DIR/capacity" 2>/dev/null || echo "0")
        STATUS=$(cat "$BAT_DIR/status" 2>/dev/null || echo "Unknown")
        MODEL=$(cat "$BAT_DIR/model_name" 2>/dev/null || echo "Generic Battery")
        HEALTH=$(cat "$BAT_DIR/health" 2>/dev/null || echo "Good")
        CYCLES=$(cat "$BAT_DIR/cycle_count" 2>/dev/null || echo "N/A")

        echo -e " Battery Model    : ${WHITE}${MODEL}${RESET}"
        echo -e " Charge Level     : $(render_bar "$CAPACITY")"
        echo -e " Power Status     : ${CYAN}${STATUS}${RESET}"
        echo -e " Battery Health   : ${GREEN}${HEALTH}${RESET}"
        if [ "$CYCLES" != "N/A" ]; then
            echo -e " Cycle Count      : ${WHITE}${CYCLES}${RESET}"
        fi
    fi

# --- 3. MACOS IMPLEMENTATION ---
elif [[ "$OS_ENV" == "macos" ]]; then
    RAW_BATT=$(pmset -g batt)
    echo -e "${WHITE} macOS Power Telemetry:${RESET}"
    echo -e "${GRAY}${RAW_BATT}${RESET}"
fi

echo -e "${CYAN}========================================================================${RESET}"
echo -e "${GRAY} Press Enter to exit...${RESET}"
read -r dummy
