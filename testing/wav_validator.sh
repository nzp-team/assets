#!/bin/bash
#
# Nazi Zombies: Portable
# Validate .WAV files are mono.
# ----
# This is intended to be used via a Docker 
# container running ubuntu:24.04.
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

    # Iterate through every .wav in our assets..
    while read -r wav_file; do
        echo "[INFO]: Verifying WAV sound file [${wav_file}].."
        local file_output=$(file "${wav_file}")

        # Check for indexed keyword
        if [[ "${file_output}" != *", mono "* ]]; then
            echo "  - ERROR: WAV [${wav_file}] is not a mono sample!"
            total_failures=$((total_failures + 1))
        fi
    done < <(find . -type f -name "*.wav")

    if [[ "${total_failures}" -ne 0 ]]; then
        echo "[ERROR]: FAILED to validate [${total_failures}] WAV sounds!"
        exit 1
    else
        echo "[PASS]: No issues found :)"
        exit 0
    fi
}

main;