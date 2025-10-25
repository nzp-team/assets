#!/bin/bash
#
# Nazi Zombies: Portable
# Validate Assets requested in .map files
# exist in repository.
# ----
# This is intended to be used via a Docker 
# container running ubuntu:24.04.
#
set -o errexit

ASSETS_ROOT=$(dirname "${BASH_SOURCE[0]}")/../
cd "${ASSETS_ROOT}"

sound_cache=""
model_cache=""

#
# item_in_cache
# ----
# parm0: item
# parm1: cache variable
# Returns 0 (true) if item is in cache, returns 1 (false) otherwise.
#
function item_in_cache()
{
    local item="${1}"
    local cache="${2}"

    while read cache_item; do 
        # Already in list, bail.
        if [[ "${item}" == "${cache_item}" ]]; then
            return 0
        fi
    done <<< "${cache}"

    # Item not in list
    return 1
}

#
# add_sound_to_cache()
# ----
# Adds a sound file to the cache list
# if not already present.
#
function add_sound_to_cache()
{
    local sound="${1}"

    # Avoid adding duplicates.
    if ! item_in_cache "${sound}" "${sound_cache}"; then
        sound_cache=$(printf '%s\n%s' "${sound_cache}" "${sound}")
    fi
}

#
# build_sound_list()
# ----
# Builds a cache of every sound in the
# repository.
#
function build_sound_list()
{
    echo "[INFO]: Building Sound cache.."

    local sound_prefix="sounds/"

    # Find every sound file in our assets
    while read -r sound; do
        # Build a cleaned path to them
        local sound_path="sounds/${sound#*$sound_prefix}"
        
        # Try to add it to our cache
        add_sound_to_cache "${sound_path}"
    done < <(find . -type f -name "*.wav")

    echo "[INFO]: Done! Sound count: [$(echo "${sound_cache}" | wc -l | xargs)]"
}

#
# add_model_to_cache()
# ----
# Adds a model file to the cache list
# if not already present.
#
function add_model_to_cache()
{
    local model="${1}"

    # Avoid adding duplicates.
    if ! item_in_cache "${model}" "${model_cache}"; then
        model_cache=$(printf '%s\n%s' "${model_cache}" "${model}")
    fi
}

#
# build_model_list()
# ----
# Builds a cache of every model in the
# repository.
#
function build_model_list()
{
    echo "[INFO]: Building Model cache.."

    local model_prefix="models/"

    # Find every model file in our assets
    while read -r model; do
        # Build a cleaned path to them
        local model_path="models/${model#*$model_prefix}"
        
        # Try to add it to our cache
        add_model_to_cache "${model_path}"
    done < <(find . -type f -name "*.mdl")

    echo "[INFO]: Done! Model count: [$(echo "${model_cache}" | wc -l | xargs)]"
}

#
# main()
# ----
# Test entry point.
#
function main()
{
    local total_failures=0

    # Build our cache to reference later.
    build_sound_list;
    build_model_list;

    # Iterate through every .map in our source..
    while read -r map_file; do
        echo "[INFO]: Verifying asset paths in [${map_file}].."

        # Check sounds first..
        while read -r sound; do
            local sound_file=$(echo "${sound}" | awk -F'"' '{print $4}')

            if item_in_cache "${sound_file}" "${sound_cache}"; then
                echo "  + FOUND: [${sound_file}]!"
            else
                echo "  - ERROR: Could NOT find [${sound_file}]!"
                total_failures=$((total_failures + 1))
            fi
        done < <(strings "${map_file}" | grep ".wav")

        # Now models..
        while read -r model; do
            local model_file=$(echo "${model}" | awk -F'"' '{print $4}')

            if item_in_cache "${model_file}" "${model_cache}"; then
                echo "  + FOUND: [${model_file}]!"
            else
                echo "  - ERROR: Could NOT find [${model_file}]!"
                total_failures=$((total_failures + 1))
            fi
        done < <(strings "${map_file}" | grep ".mdl")

    done < <(find . -type f -name "*.map")

    if [[ "${total_failures}" -ne 0 ]]; then
        echo "[ERROR]: FAILED to find [${total_failures}] assets!"
        exit 1
    else
        echo "[PASS]: No issues found :)"
        exit 0
    fi
}

main;