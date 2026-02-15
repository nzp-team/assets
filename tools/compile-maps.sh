#!/bin/bash
#
# Nazi Zombies: Portable
# Map compilation script for Linux x86_64,
# requires wget, unzip.
#
set -o errexit
set -o xtrace

ASSETS_ROOT=$(dirname "${BASH_SOURCE[0]}")/../
cd "${ASSETS_ROOT}"

VHLT_URL="https://github.com/nzp-team/vhlt/releases/download/Vanilla/vhlt-v34-linux-x86_64.zip"

FULL_COMPILE="0"

# These are global options that apply to all maps.
HLCSG_PARMS="-threads 8 -nowadtextures -wadautodetect"
HLBSP_PARMS="-threads 8"
HLVIS_PARMS="-threads 8"
HLRAD_PARMS="-threads 8"

# Map specific flags
hlbsp_args=""
hlcsg_args=""
hlvis_args=""
hlrad_args=""

while true; do
    case "$1" in
        -f | --full ) FULL_COMPILE="1"; shift 1 ;;
        -m | --map ) MAP_TO_COMPILE="$2"; shift 2 ;;
        -z | --zone-tool-path ) ZONE_TOOL_PATH="$2"; shift 2 ;;
        -- ) shift; break ;;
        * ) break ;;
    esac
done

# If running with --full, append extra arguments
if [[ "${FULL_COMPILE}" -ne "0" ]]; then
    echo "[INFO]: Compiling with final arguments enabled."

    HLCSG_PARMS="${HLCSG_PARMS} -cliptype precise"
    HLVIS_PARMS="${HLVIS_PARMS} -full"
    HLRAD_PARMS="${HLRAD_PARMS} -extra"
fi

#
# download_dependencies()
# ----
# Downloads VHLT.
#
function download_dependencies()
{
    # Nothing to do.
    if [[ -f "tools/vhlt/hlbsp" ]]; then
        return 0
    fi

    echo "[INFO]: Downloading VHLT.."

    # Download with wget
    wget -P tools/ "${VHLT_URL}"
    unzip tools/vhlt-v34-linux-x86_64.zip -d tools/vhlt/
    chmod +x tools/vhlt/*
    rm tools/vhlt-v34-linux-x86_64.zip
}

#
# compile_individual_level()
# ----
# Attempts compilation of a specific map.
# called by compile_levels().
#
function compile_individual_level()
{
    local map_file="$1"
    local command=""
    local pretty_name=$(basename ${map_file} .map)
    local map_path="source/maps/${pretty_name}/${pretty_name}"
    hlbsp_args=""
    hlcsg_args=""
    hlvis_args=""
    hlrad_args=""

    echo "[INFO]: Starting compilation of [${pretty_name}].."

    if [[ -f "${map_path}.args" ]]; then
        echo "  + Found arguments file!"
        source "${map_path}.args"
    fi

    cd "source/maps/${pretty_name}"

    # Grrr..... Windows....
    # Swap backslashes in wad key with forward slashes
    sed -i '/^"wad"/ s|\\|/|g' ${pretty_name}.map

    # 1. hlcsg
    command="../../../tools/vhlt/hlcsg ${HLCSG_PARMS} ${hlcsg_args} ${pretty_name}.map"
    echo "[${command}]"
    $command

    # 2. hlbsp
    command="../../../tools/vhlt/hlbsp ${HLBSP_PARMS} ${hlbsp_args} ${pretty_name}.map"
    echo "[${command}]"
    $command

    # 3. hlvis
    command="../../../tools/vhlt/hlvis ${HLVIS_PARMS} ${hlvis_args} ${pretty_name}.bsp"
    echo "[${command}]"
    $command

    # 4. hlrad
    command="../../../tools/vhlt/hlrad ${HLRAD_PARMS} ${hlrad_args} ${pretty_name}.bsp"
    echo "[${command}]"
    $command

    # 5. zone tool
    if [[ -n "${ZONE_TOOL_PATH}" ]]; then
        local python_path=$(which python3)
        command="${python_path} ${ZONE_TOOL_PATH}/spawn_zone_tool.py ${pretty_name}.map --output ../../../common/maps/${pretty_name}.nsz"
        echo "[${command}]"
        $command

        # Maps may not have zones, just delete empty files.
        if grep -q "number_of_zones: 0" "../../../common/maps/${pretty_name}.nsz"; then
            echo "Zero Zones for [${pretty_name}], deleting empty NSZ.."
            rm -rf ../../../common/maps/${pretty_name}.nsz
        fi
    fi

    cd "../../../"

    mv "${map_path}.bsp" "common/maps/${pretty_name}.bsp"
    find source/maps/${pretty_name} -type f ! -name '*.map' ! -name '*.args' -delete
}

#
# compile_levels()
# ----
# Attempts to compile maps specified.
#
function compile_levels()
{
    # Iterate through every .map in our source..
    if [[ -z "${MAP_TO_COMPILE}" ]]; then
        while read -r map_file; do
            if [[ "${map_file}" == "source/maps/template.map" ]]; then
                continue
            fi
            compile_individual_level "${map_file}"
        done < <(find source/maps/ -type f -name "*.map")
    else
        compile_individual_level "source/maps/${MAP_TO_COMPILE}"
    fi
}

#
# main()
# ----
# Entry point.
#
function main()
{
    rm -rf common/maps/*.bsp

    download_dependencies;
    compile_levels;

    echo "[INFO]: Done! :)"
}

main;