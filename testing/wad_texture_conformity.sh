#!/bin/bash
#
# Nazi Zombies: Portable
# Validate textures used to build .WAD
# files conform to standards.
# ----
# This is intended to be used via a Docker 
# container running ubuntu:24.04.
#
set -o errexit

ASSETS_ROOT=$(dirname "${BASH_SOURCE[0]}")/../
cd "${ASSETS_ROOT}"

#
# test_no_asterisk_in_paths()
# ----
# Ensures none of the WAD textures
# contain an asterisk (*) in their path names.
#
function test_no_asterisk_in_paths()
{
    echo "[INFO]: Ensuring no WAD textures have an asterisk in their name.."
    echo ""
    cd "${ASSETS_ROOT}/source/textures/wad"

    local old_ifs=${IFS}
    local found_bad_file="0"

    while IFS= read -r -d '' file; do
        echo "[ERROR]: Found texture with asterisk in path: [${file:2}]"
        found_bad_file="1"
    done < <(find . -name '*[*]*' -print0)

    IFS=${old_ifs}

    echo ""

    if [[ "${found_bad_file}" -ne "0" ]]; then
        echo "[ERROR]: Found file(s) with an asterisk in its path. These files make"
        echo "         Windows very angry. For water textures, please use '$' in"
        echo "         place of '*'. We will convert back during WAD building."
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
    test_no_asterisk_in_paths;

    echo "[PASS]: No issues found :)"
    exit 0
}

main;