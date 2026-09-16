#!/usr/bin/env bash

# --- Check for bat command ---
BAT_CMD="bat"
if ! command -v "$BAT_CMD" &> /dev/null; then
    # On Debian/Ubuntu, it may be installed as 'batcat' due to a package name conflict
    if command -v "batcat" &> /dev/null; then
        BAT_CMD="batcat"
    else
        echo "Error: 'bat' (or 'batcat') is not installed or not in PATH." >&2
        exit 1
    fi
fi

# --- Automatic encoding detection function (UTF-8 vs CP949) ---
detect_encoding() {
    local target_file="$1"
    
    # If the file is 0 bytes, treat it as UTF-8 by default
    if [ ! -s "$target_file" ]; then
        echo "UTF-8"
        return
    fi

    # 1. Strictly validate if the file is valid UTF-8 using iconv
    if iconv -f UTF-8 -t UTF-8 "$target_file" >/dev/null 2>&1; then
        echo "UTF-8"
    else
        # 2. If it contains invalid UTF-8 byte sequences, fallback to CP949
        echo "CP949"
    fi
}

# --- Show help usage ---
show_help() {
    echo "Usage:"
    echo "  vbat.sh [filename/pattern] [--encoding=value] [-e value]"
    exit 0
}

# --- Parse arguments ---
file_pattern=""
enc_override=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        --encoding=*)
            enc_override="${1#*=}"
            shift
            ;;
        -e|--encoding)
            if [ -n "$2" ]; then
                enc_override="$2"
                shift 2
            else
                echo "Error: Missing argument for $1" >&2
                exit 1
            fi
            ;;
        *)
            file_pattern="$1"
            shift
            ;;
    esac
done

if [ -z "$file_pattern" ]; then
    echo "Error: Missing filename or pattern. Type 'vbat.sh -h' for help." >&2
    exit 1
fi

# --- Retrieve file list (supports wildcard patterns) ---
# Prevent unexpanded wildcards from returning literal pattern string
shopt -s nullglob
files=($file_pattern)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo "File(s) not found: $file_pattern" >&2
    exit 1
fi

# --- Process encoding per file and execute bat ---
for f in "${files[@]}"; do
    if [ ! -f "$f" ]; then
        continue
    fi

    current_enc=""

    # 1) Check command-line override option
    if [ -n "$enc_override" ]; then
        current_enc="$enc_override"
    else
        # 2) Check for adjacent .encoding metadata file
        meta_file="${f}.encoding"
        if [ -f "$meta_file" ]; then
            # Parse 'encoding=value'
            matched_val=$(grep -E '^[[:space:]]*encoding[[:space:]]*=' "$meta_file" | head -n 1 | sed -E 's/^[[:space:]]*encoding[[:space:]]*=[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$matched_val" ]; then
                current_enc="$matched_val"
            fi
        fi
    fi

    # 3) Fallback to auto-detection if no encoding is explicitly specified
    if [ -z "$current_enc" ]; then
        current_enc=$(detect_encoding "$f")
    fi

    # Standardize encoding aliases to uppercase
    current_enc_upper=$(echo "$current_enc" | tr '[:lower:]' '[:upper:]')
    case "$current_enc_upper" in
        949|EUC-KR)
            current_enc="CP949"
            ;;
        UTF8)
            current_enc="UTF-8"
            ;;
    esac

    # Display directly if UTF-8, otherwise convert to UTF-8 via iconv and pipe to bat
    if [ "$current_enc_upper" = "UTF-8" ]; then
        "$BAT_CMD" "$f"
    else
        if ! iconv -f "$current_enc" -t UTF-8 "$f" 2>/dev/null | "$BAT_CMD" --file-name "$(basename "$f")"; then
            echo "Error: Failed to decode '$f' with encoding '$current_enc'" >&2
        fi
    fi
done
