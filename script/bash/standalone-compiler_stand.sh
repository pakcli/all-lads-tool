#!/usr/bin/env bash
# ==============================================================================
# STANDALONE-COMPILER_STAND.SH
# Inlines sourced Bash modules from module/ into a standalone <name>_stand.sh script.
# ==============================================================================

SOURCE_FILE="${1:-}"
OUTPUT_FILE="${2:-}"

if [ -z "$SOURCE_FILE" ]; then
    echo "Usage: ./standalone-compiler_stand.sh <source_file.sh> [output_stand.sh]"
    exit 1
fi

if [ -z "$OUTPUT_FILE" ]; then
    base_name="$(basename "$SOURCE_FILE" .sh)"
    base_name="${base_name%_stand}"
    OUTPUT_FILE="$(dirname "$SOURCE_FILE")/${base_name}_stand.sh"
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "[*] Compiling Bash script: $(basename "$SOURCE_FILE") -> $OUTPUT_FILE ..."

{
    echo "#!/usr/bin/env bash"
    echo "# =============================================================================="
    echo "# COMPILED STANDALONE BASH SCRIPT - ALL-LADS-TOOL"
    echo "# Source: $(basename "$SOURCE_FILE") | Built: $(date)"
    echo "# =============================================================================="
    echo ""

    while IFS= read -r line; do
        if [[ "$line" =~ source\ .*/module/(.+)\.sh ]] || [[ "$line" =~ \.\ .*/module/(.+)\.sh ]]; then
            mod_name="${BASH_REMATCH[1]}.sh"
            mod_path="$(dirname "$SOURCE_FILE")/module/$mod_name"
            if [ -f "$mod_path" ]; then
                echo "# --- [INLINED MODULE: $mod_name] ---"
                cat "$mod_path"
                echo "# --- [END INLINED MODULE: $mod_name] ---"
                echo ""
            else
                echo "$line"
            fi
        else
            echo "$line"
        fi
    done < "$SOURCE_FILE"
} > "$OUTPUT_FILE"

chmod +x "$OUTPUT_FILE" 2>/dev/null || true
echo "[OK] Standalone Bash script generated: $OUTPUT_FILE"
