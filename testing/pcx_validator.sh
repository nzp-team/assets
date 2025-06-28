#!/bin/bash
#
# Nazi Zombies: Portable
# Validate .PCX files are of an indexed 8-bit color
# and the dimensions are power-of-two.
# ----
# This is intended to be used via a Docker 
# container running ubuntu:24.10.
#
set -o errexit

ASSETS_ROOT=$(dirname "${BASH_SOURCE[0]}")/../
cd "${ASSETS_ROOT}"

source "${ASSETS_ROOT}/testing/utils.sh"

#
# main()
# ----
# Test entry point.
#
function main()
{
    local total_failures=0

    # Iterate through every .pcx in our assets..
    while read -r pcx_file; do
        echo "[INFO]: Verifying PCX texture file [${pcx_file}].."
        local file_output=$(file "${pcx_file}")

        # Check for indexed keyword
        if [[ "${file_output}" != *", 8-bit "* ]]; then
            echo "  - ERROR: PCX [${pcx_file}] is not of 8-bit indexed color!"
            total_failures=$((total_failures + 1))
        fi

        # Evil regex to get the second bounding box (zero-offset width and height)
        if [[ "${file_output}" =~ \[([0-9]+),[[:space:]]*([0-9]+)\][[:space:]]*-[[:space:]]*\[([0-9]+),[[:space:]]*([0-9]+)\] ]]; then
            x1="${BASH_REMATCH[3]}"
            y1="${BASH_REMATCH[4]}"
            
            width=$((x1 + 1))
            height=$((y1 + 1))

            if ! is_pow2 "$width" || ! is_pow2 "$height"; then
                echo "  - ERROR: Dimensions of .PCX [${pcx_file}] are not a power-of-two: [${width}x${height}]!"
                total_failures=$((total_failures + 1))
            fi
        else
            echo "  - ERROR: Could not parse bounding box info, is [${pcx_file}] a real .PCX?"
            total_failures=$((total_failures + 1))
        fi
    done < <(find . -type f -name "*.pcx")

    if [[ "${total_failures}" -ne 0 ]]; then
        echo "[ERROR]: FAILED to validate [${total_failures}] PCX textures!"
        exit 1
    else
        echo "[PASS]: No issues found :)"
        exit 0
    fi
}

main;