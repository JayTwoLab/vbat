#!/usr/bin/env bash

# vbat.sh: Enhanced bat wrapper for Bash environments
# Supports wildcards, custom encodings, and .encoding sidecar files.
# Default encoding is strictly set to UTF-8.

show_help() {
    echo "Usage:"
    echo "  ./vbat.sh [filename/pattern] [--encoding=value] [-e value]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -e, --encoding=      Specify file encoding (e.g., UTF-8, CP949, EUC-KR)"
    echo "                       (Defaults to UTF-8 if omitted)"
    exit 0
}

file_pattern=""
enc_override=""

# 1. Parse Arguments Safely
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        --encoding=*)
            enc_override="${1#*=}"
            shift
            ;;
        -e|--encoding)
            if [[ -n "$2" && "$2" != -* ]]; then
                enc_override="$2"
                shift 2
            else
                echo "Error: Argument for $1 is missing." >&2
                exit 1
            fi
            ;;
        *)
            file_pattern="$1"
            shift
            ;;
    esac
done

# 2. Validation: Check Missing Path
if [[ -z "$file_pattern" ]]; then
    echo "Error: Missing filename or pattern. Type \`./vbat.sh -h\` for help." >&2
    exit 1
fi

# 3. Process Files (Handles Wildcards natively via Bash Expansion)
shopt -s nullglob
files=($file_pattern)
shopt -u nullglob

if [[ ${#files[@]} -eq 0 ]]; then
    echo "Error: File(s) not found: $file_pattern" >&2
    exit 1
fi

for file in "${files[@]}"; do
    if [[ ! -f "$file" ]]; then
        continue
    fi

    $current_enc="UTF-8" # Default Fallback

    if [[ -n "$enc_override" ]]; then
        current_enc="$enc_override"
    else
        meta_file="${file}.encoding"
        if [[ -f "$meta_file" ]]; then
            while IFS= read -r line || [[ -n "$line" ]]; do
                if [[ "$line" =~ ^[[:space:]]*encoding[[:space:]]*=[[:space:]]*(.+)$ ]]; then
                    current_enc=$(echo "${BASH_REMATCH[1]}" | xargs)
                    break
                fi
            done < "$meta_file"
        fi
    fi

    # Normalize Encoding Names for iconv compatibility
    if [[ "${current_enc,,}" == "utf8" || "${current_enc,,}" == "default" ]]; then
        current_enc="UTF-8"
    fi

    # 4. Validate Encoding with iconv
    if ! iconv -l | grep -qi "^${current_enc}$"; then
        if ! iconv -f "$current_enc" -t UTF-8 <<< "" &>/dev/null; then
            echo "Error: Unsupported encoding '$current_enc' for file $(basename "$file")" >&2
            continue
        fi
    fi

    # 5. Read, Convert, and Pipeline to 'bat'
    iconv -f "$current_enc" -t UTF-8 "$file" 2>/dev/null | bat --file-name "$(basename "$file")"
done