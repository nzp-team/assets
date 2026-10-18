#!/bin/bash
#
# Nazi Zombies: Portable
# Runs Vril's comprehensive Pathfind and AI test.
# ----
# This is intended to be used via a Docker 
# container running ubuntu:24.04.
#
set -o errexit

assets_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
binary=""
game="${GAME_DIR:-/workspace/game}"
output="$assets_root/tmp/pathfind"
timeout_seconds=14400
source_node=""
destination_node=""
direct_walk=""
maps=()
if [[ -n "${MAP:-}" ]]; then
    maps+=("$MAP")
fi

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --binary|--game|--output|--map|--timeout|--source|--destination)
            if [[ "$#" -lt 2 ]]; then
                echo "Missing value for $1" >&2
                exit 2
            fi
            case "$1" in
                --binary) binary="$2" ;;
                --game) game="$2" ;;
                --output) output="$2" ;;
                --map) maps+=("$2") ;;
                --timeout) timeout_seconds="$2" ;;
                --source) source_node="$2" ;;
                --destination) destination_node="$2" ;;
            esac
            shift 2
            ;;
        --direct) direct_walk="direct"; shift ;;
        --edges) direct_walk="edges"; shift ;;
        --help|-h)
            echo "Usage: pathfind.sh [--binary path --game path] [--map name] [--output path] [--timeout seconds] [--source index --destination index [--direct]] [--edges]"
            exit 0
            ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done

if [[ "$direct_walk" == "direct" && ( -z "$source_node" || -z "$destination_node" ) ]]; then
    echo "--direct requires --source and --destination." >&2
    exit 2
fi

if [[ "$direct_walk" == "edges" && ( -n "$source_node" || -n "$destination_node" ) ]]; then
    echo "--edges cannot be combined with --source or --destination." >&2
    exit 2
fi

function prepare_game()
{
    local map
    local source_map

    echo '[INFO]: Building map content for pathfind validation...'
    /entrypoint.sh build-wads

    if [[ "${#maps[@]}" -eq 0 ]]; then
        /entrypoint.sh build-map --full

        shopt -s nullglob
        for source_map in "$assets_root"/source/maps/*/*.map; do
            map="$(basename "$(dirname "$source_map")")"
            if [[ "$(basename "$source_map")" == "$map.map" ]]; then
                maps+=("$map")
            fi
        done
    else
        for map in "${maps[@]}"; do
            /entrypoint.sh build-map --map "$map" --full
        done
    fi

    echo '[INFO]: Preparing checked-out assets for pathfind validation...'
    rm -rf "$assets_root/tmp/nzp" "$assets_root/tmp/pc"
    /entrypoint.sh build-assets
    mkdir -p "$game/nzp"

    if [[ "$game" != /workspace/game ]]; then
        cp -a "$assets_root/tmp/pc/." "$game/"
    fi

    echo '[INFO]: Building Vril for pathfind validation..'
    /entrypoint.sh build-vril --target linux-x86_64 --clean
    binary="$game/nzportable64"
    cp /workspace/repos/vril-engine/build/sdl/nzportable "$binary"
    chmod +x "$binary"

    echo '[INFO]: Building standard QuakeC for pathfind validation...'
    /entrypoint.sh build-quakec
    cp /workspace/repos/quakec/build/standard/progs.dat "$game/nzp/progs.dat"
}

function main()
{
    local map
    local bsp
    local i
    local status
    local failed=0
    local config

    if [[ -z "$binary" ]]; then
        prepare_game
    fi

    binary="$(cd "$(dirname "$binary")" && pwd)/$(basename "$binary")"
    game="$(cd "$game" && pwd)"
    mkdir -p "$output"
    output="$(cd "$output" && pwd)"

    if [[ "${#maps[@]}" -eq 0 ]]; then
        shopt -s nullglob
        for bsp in "$game"/nzp/maps/*.bsp; do
            maps+=("$(basename "$bsp" .bsp)")
        done
    fi

    if [[ "${#maps[@]}" -eq 0 ]]; then
        echo "[ERROR]: No compiled maps found."
        return 1
    fi

    config="$game/nzp/pathfind-run.cfg"
    trap 'rm -f "$game/nzp/pathfind-run.cfg"' EXIT

    for map in "${maps[@]}"; do
        rm -f "$game/nzp/pathfind-report.json" "$output/$map.json"

        {
            printf 'sv_cheats 1\npathfind_test_exit 1\nmap %s\n' "$map"
            for ((i=0; i<40; i++)); do
                printf 'wait\n'
            done
            if [[ "$direct_walk" == "edges" ]]; then
                printf 'pathfind_test edges\n'
            else
                printf 'pathfind_test %s %s %s\n' "$source_node" "$destination_node" "$direct_walk"
            fi
        } > "$config"

        echo "[INFO]: Testing pathfinding and zombie walking: $map"
        status=0
        timeout --kill-after=3 "$timeout_seconds" "$binary" -basedir "$game" -dedicated 1 -nosound -nocdaudio +vid_renderer headless +developer 0 +host_framerate 0.05 +sys_ticrate 0.001 +cl_maxfps 1000000 +exec pathfind-run.cfg > "$output/$map.log" 2>&1 || status=$?

        if [[ -f "$game/nzp/pathfind-report.json" ]]; then
            cp "$game/nzp/pathfind-report.json" "$output/$map.json"
        fi

        if [[ "$status" -eq 0 ]] && grep -q '^Pathfind test command passed\.' "$output/$map.log" && [[ -f "$output/$map.json" ]] && grep -F -q "\"walk_mode\":\"${direct_walk:-path}\"" "$output/$map.json"; then
            echo "[PASS]: $map"
        else
            echo "[ERROR]: $map failed (exit status $status; see $output/$map.log)"
            failed=1
        fi
    done

    return "$failed"
}

main
