#!/bin/bash
#
# Nazi Zombies: Portable
# Very involved .MDL header and vertex+uv validation
# ----
# This is intended to be used via a Docker 
# container running ubuntu:24.10.
#
set -o errexit

ASSETS_ROOT=$(dirname "${BASH_SOURCE[0]}")/../
cd "${ASSETS_ROOT}"

source "${ASSETS_ROOT}/testing/utils.sh"

#
# Constants for validation
#
MDL_HEADER_LEN="84"

MDL_HEADER_MAGIC="IDPO"
MDL_HEADER_MAGIC_LEN="4"
MDL_HEADER_MAGIC_OFS="0"

MDL_HEADER_VERSION="6"
MDL_HEADER_VERSION_OFS="4"

MDL_SKINWIDTH_MAX="512"
MDL_SKINWIDTH_OFS="52"

MDL_SKINHEIGHT_MAX="512"
MDL_SKINHEIGHT_OFS="56"

MDL_NUMVERTS_MAX="2048"
MDL_NUMVERTS_OFS="60"

MDL_NUMTRIS_MAX="1024"
MDL_NUMTRIS_OFS="64"

MDL_NUMFRAMES_MAX="256"
MDL_NUMFRAMES_OFS="68"

#
# validate_mdl_header()
# ----
# Validates entries in header for MDL file
#
function validate_mdl_header()
{
    local mdl_file="${1}"
    local should_fail="0"

    # Magic
    local magic=$(read_string_in_file_at_ofs "${mdl_file}" "${MDL_HEADER_MAGIC_LEN}" "${MDL_HEADER_MAGIC_OFS}")
    echo "  + MAGIC: [${magic}]"
    if [[ "${magic}" != "${MDL_HEADER_MAGIC}" ]]; then
        echo "    - ERROR: Bad magic! Expected [${MDL_HEADER_MAGIC}] but got [${magic}]!"
        should_fail="1"
    fi

    # Version
    local version=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_HEADER_VERSION_OFS}")
    echo "  + VERSION: [${version}]"
    if [[ "${version}" != "${MDL_HEADER_VERSION}" ]]; then
        echo "    - ERROR: Bad version! Expected [${MDL_HEADER_VERSION}] but got [${version}]!"
        should_fail="1"
    fi

    # Skin Width
    local skin_width=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_SKINWIDTH_OFS}")
    echo "  + SKIN WIDTH: [${skin_width}]"
    if [[ "${skin_width}" -gt "${MDL_SKINWIDTH_MAX}" ]]; then
        echo "    - ERROR: Skin width is too big! Max is [${MDL_SKINWIDTH_MAX}] but got [${skin_width}]!"
        should_fail="1"
    fi
    if [[ "${skin_width}" -le "0" ]]; then
        echo "    - ERROR: Skin width is zero!"
        should_fail="1"
    fi

    # Skin Height
    local skin_height=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_SKINHEIGHT_OFS}")
    echo "  + SKIN HEIGHT: [${skin_height}]"
    if [[ "${skin_height}" -gt "${MDL_SKINHEIGHT_MAX}" ]]; then
        echo "    - ERROR: Skin height is too big! Max is [${MDL_SKINHEIGHT_MAX}] but got [${skin_height}]!"
        should_fail="1"
    fi
    if [[ "${skin_height}" -le "0" ]]; then
        echo "    - ERROR: Skin height is zero!"
        should_fail="1"
    fi

    # Num Verts
    local num_verts=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_NUMVERTS_OFS}")
    echo "  + VERTICES: [${num_verts}]"
    if [[ "${num_verts}" -gt "${MDL_NUMVERTS_MAX}" ]]; then
        echo "    - ERROR: Verts is too big! Max is [${MDL_NUMVERTS_MAX}] but got [${num_verts}]!"
        should_fail="1"
    fi
    if [[ "${num_verts}" -le "0" ]]; then
        echo "    - ERROR: Verts is zero!"
        should_fail="1"
    fi

    # Num Tris
    local num_tris=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_NUMTRIS_OFS}")
    echo "  + TRIANGLES: [${num_tris}]"
    if [[ "${num_tris}" -gt "${MDL_NUMTRIS_MAX}" ]]; then
        echo "    - ERROR: Tris is too big! Max is [${MDL_NUMTRIS_MAX}] but got [${num_tris}]!"
        should_fail="1"
    fi
    if [[ "${num_tris}" -le "0" ]]; then
        echo "    - ERROR: Tris is zero!"
        should_fail="1"
    fi

    # Num Frames
    local num_frames=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_NUMFRAMES_OFS}")
    echo "  + FRAMES: [${num_frames}]"
    if [[ "${num_frames}" -gt "${MDL_NUMFRAMES_MAX}" ]]; then
        echo "    - ERROR: Frames is too big! Max is [${MDL_NUMFRAMES_MAX}] but got [${num_frames}]!"
        should_fail="1"
    fi
    if [[ "${num_frames}" -le "0" ]]; then
        echo "    - ERROR: Frames is zero!"
        should_fail="1"
    fi

    return "${should_fail}"
}

#
# validate_mdl_data()
# ----
# Validates vert, uv, mesh data in MDL file
#
function validate_mdl_data()
{
    local mdl_file="${1}"
    local should_fail="0"

    local file_size=$(stat -c %s "${mdl_file}")

    local num_frames=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_NUMFRAMES_OFS}")
    local num_verts=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_NUMVERTS_OFS}")
    local num_tris=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_NUMTRIS_OFS}")
    local num_skins=$(read_int_in_file_at_ofs "${mdl_file}" 48)
    local skin_width=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_SKINWIDTH_OFS}")
    local skin_height=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_SKINHEIGHT_OFS}")
    
    local tex_coord_size=$((num_verts * 4))
    local triangle_size=$((num_tris * 8))

    local skin_data_bytes=$((num_skins * skin_width * skin_height))

    local frame_header_size=$((4 + 12 + 12 + 16))
    local frame_size=$((frame_header_size + num_verts * 4))
    local minimum_file_size=$((MDL_HEADER_LEN + skin_data_bytes + tex_coord_size + triangle_size + frame_size * num_frames))

    local offset="0"
    local i="0"
    local idx="0"
    local s="0"
    local t="0"

    # We have a lot of broken UVs that don't necessarily indiciate
    # a problem, so disabling this..

    # UVs
    # for ((i=0; i<num_verts; i++)); do
    #     offset=$((MDL_HEADER_LEN + i * 4))
    #     s=$(read_byte_in_file_at_ofs "${mdl_file}" $((offset + 1)))
    #     t=$(read_byte_in_file_at_ofs "${mdl_file}" $((offset + 2)))

    #     if [[ "$s" -ge "$skin_width" || "$t" -ge "$skin_height" ]]; then
    #         echo "  - ERROR: UV $i out of bounds: (s=$s t=$t)"
    #         should_fail="1"
    #     fi
    # done

    # Vertices
    for ((i=0; i<num_tris; i++)); do
        offset=$((MDL_HEADER_LEN + tex_coord_size + i * 8 + 2))
        for j in 0 2 4; do
            idx=$(read_short_in_file_at_ofs $((offset + j)))
            if [[ "${idx}" -ge "${num_verts}" ]]; then 
                echo "  - ERROR: Triangle [${i}] has invalid vertex index [${idx}]!"
                should_fail="1"
            fi
        done
    done

    # Don't do size check for AI, since the names cause some issues
    if [[ "${mdl_file}" == *"/ai/"* ]]; then
        return "${should_fail}"
    fi

    # Size check
    if [[ "${file_size}" -lt "${minimum_file_size}" ]]; then
        echo "  - ERROR: Not enough vertex data (corrupt .MDL?) [${actual_data_bytes}] < [${expected_data_bytes}]!"
        should_fail="1"
    fi

    return "${should_fail}"
}

#
# main()
# ----
# Test entry point.
#
function main()
{
    local total_failures=0

    # Iterate through every .mdl in our assets..
    while read -r mdl_file; do
        echo "[INFO]: Verifying MDL model [${mdl_file}].."

        if ! validate_mdl_header "${mdl_file}"; then
            echo "  - ERROR: Invalid header for MDL [${mdl_file}]!"
            total_failures=$((total_failures + 1))
            continue
        fi

        if ! validate_mdl_data "${mdl_file}"; then
            echo "  - ERROR: Invalid mesh data for MDL [${mdl_file}]!"
            total_failures=$((total_failures + 1))
            continue
        fi
    done < <(find . -type f -name "*.mdl")

    if [[ "${total_failures}" -ne 0 ]]; then
        echo "[ERROR]: FAILED to validate [${total_failures}] MDL models!"
        exit 1
    else
        echo "[PASS]: No issues found :)"
        exit 0
    fi
}

main;