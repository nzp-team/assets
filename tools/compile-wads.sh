#!/bin/bash
#
# Nazi Zombies: Portable
# WAD compilation script for Linux x86_64,
# requires wget, unzip, libicu-dev.
#
set -o errexit

ASSETS_ROOT=$(dirname "${BASH_SOURCE[0]}")/../
cd "${ASSETS_ROOT}"

WADMAKER_URL="https://github.com/pwitvoet/wadmaker/releases/download/1.3/WadMaker_1.3_linux64.zip"

#
# download_dependencies()
# ----
# Downloads WadMaker.
#
function download_dependencies()
{
    # Nothing to do.
    if [[ -f "tools/wadmaker/WadMaker" ]]; then
        return 0
    fi

    echo "[INFO]: Downloading WadMaker.."

    # Download with wget
    wget -P tools/ "${WADMAKER_URL}"
    unzip -j tools/WadMaker_1.3_linux64.zip -d tools/wadmaker/ || ignore=$?
    chmod +x tools/wadmaker/WadMaker
    rm -f tools/WadMaker_1.3_linux64.zip
}

#
# compile_wads()
# ----
# Attempts to compile all WADs from 
# source/textures/wad/ directory.
#
function compile_wads()
{
    # Iterate through every texture wad directory..
    while read -r wad_path; do
        local pretty_name=$(basename ${wad_path})
        local textures_have_spaces="0"

        echo "[INFO]: Starting compilation of WAD [${pretty_name}].."

        echo "  + First affirming that filenames contain no spaces.."
        while read -r texture_with_space; do
            echo "    - ERROR: Texture [$(basename "${texture_with_space}")] has a space, this is not allowed!"
            textures_have_spaces="1"
        done < <(find source/textures/wad/${pretty_name} -type f -name "* *" -print)

        if [[ "${textures_have_spaces}" -ne "0" ]]; then
            exit 1
        fi
        echo "    + Looks good!"

        echo "  + Using WadMaker to pack into [${pretty_name}.wad].."
        local command="tools/wadmaker/WadMaker ${wad_path} ${pretty_name}.wad -nologfile"

        echo "  + [${command}]"
        $command

        if [[ "$?" -ne "0" ]]; then
            echo "    + WadMaker FAILED!!"
            exit 1
        fi

        echo "  + Done!"

        echo " "
    done < <(find source/textures/wad -depth -mindepth 1 -maxdepth 1 -type d -print)
}

#
# main()
# ----
# Entry point.
#
function main()
{
    rm -rf source/textures/wad/*.wad

    download_dependencies;
    compile_wads;

    echo "[INFO]: Done! :)"
}

main;