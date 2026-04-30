#!/bin/bash
#
# Nazi Zombies: Portable
# Validate that .MAP files conform to standards.
# ----
# This is intended to be used via a Docker 
# container running ubuntu:24.04.
#
set -o errexit

ASSETS_ROOT=$(dirname "${BASH_SOURCE[0]}")/../
cd "${ASSETS_ROOT}"

#
# test_no_backslashes_in_wad_paths()
# ----
# Ensures there are no backslashes in
# a .MAP's WAD paths, caused by Windows.
#
function test_no_backslashes_in_wad_paths()
{
    echo "[INFO]: Ensuring no .MAP files use backslashes in their WAD paths.."
    echo ""
    cd "${ASSETS_ROOT}/source/maps"

    local old_ifs=${IFS}
    local found_bad_file="0"

     # Iterate through every .map in our source..
    while read -r map_file; do
        echo "[INFO]: Verifying [${map_file}].."

        if grep "\"wad\"" "${map_file}" | grep -q '\\'; then
            echo "[ERROR]: Found backslash in \"wad\" key. Please update to use forward slashes."
            echo ""
            found_bad_file="1"
        fi
    done < <(find . -type f -name "*.map")

    echo ""

    if [[ "${found_bad_file}" -ne "0" ]]; then
        exit 1
    fi

    echo ""
    echo ""
    echo ""
}

#
# main()
# ----
# Test entry point.
#
function main()
{
    test_no_backslashes_in_wad_paths;

    echo "[PASS]: No issues found :)"
    exit 0
}

main;