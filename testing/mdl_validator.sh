#!/bin/bash
#
# Nazi Zombies: Portable
# Very involved .MDL header and vertex+uv validation
# ----
# This is intended to be used via a Docker 
# container running ubuntu:24.04.
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

MDL_NUMTRIS_MAX="2048"
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
    if (( skin_width % 4 != 0 )); then
        echo "    - ERROR: Skin width is not multiple of four!"
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

    local file_size=$(wc -c < "${mdl_file}")

    local num_frames=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_NUMFRAMES_OFS}")
    local num_verts=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_NUMVERTS_OFS}")
    local num_tris=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_NUMTRIS_OFS}")
    local num_skins=$(read_int_in_file_at_ofs "${mdl_file}" 48)
    local skin_width=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_SKINWIDTH_OFS}")
    local skin_height=$(read_int_in_file_at_ofs "${mdl_file}" "${MDL_SKINHEIGHT_OFS}")

    local skin_size=$((skin_width * skin_height))
    local offset="${MDL_HEADER_LEN}"
    local i="0"
    local j="0"
    local idx="0"
    local group="0"
    local group_items="0"
    local record_size="0"

    # Skins are prefixed by a group flag. Grouped skins additionally contain
    # a count, one interval per image, and that many skin images.
    for ((i=0; i<num_skins; i++)); do
        if ((offset + 4 > file_size)); then
            echo "  - ERROR: Skin [${i}] header extends beyond end of file!"
            return 1
        fi
        group=$(read_int_in_file_at_ofs "${mdl_file}" "${offset}")
        offset=$((offset + 4))

        if [[ "${group}" -eq 0 ]]; then
            record_size="${skin_size}"
        else
            if ((offset + 4 > file_size)); then
                echo "  - ERROR: Skin group [${i}] header extends beyond end of file!"
                return 1
            fi
            group_items=$(read_int_in_file_at_ofs "${mdl_file}" "${offset}")
            if [[ "${group_items}" -le 0 ]]; then
                echo "  - ERROR: Skin group [${i}] has invalid image count [${group_items}]!"
                return 1
            fi
            offset=$((offset + 4))
            record_size=$((group_items * 4 + group_items * skin_size))
        fi

        if ((offset + record_size > file_size)); then
            echo "  - ERROR: Skin data [${i}] extends beyond end of file!"
            return 1
        fi
        offset=$((offset + record_size))
    done

    # stvert_t contains three 32-bit integers: onseam, s, and t.
    record_size=$((num_verts * 12))
    if ((offset + record_size > file_size)); then
        echo "  - ERROR: Texture-coordinate data extends beyond end of file!"
        return 1
    fi
    offset=$((offset + record_size))

    # dtriangle_t contains facesfront followed by three 32-bit vertex indices.
    for ((i=0; i<num_tris; i++)); do
        if ((offset + 16 > file_size)); then
            echo "  - ERROR: Triangle data [${i}] extends beyond end of file!"
            return 1
        fi
        for j in 4 8 12; do
            idx=$(read_int_in_file_at_ofs "${mdl_file}" $((offset + j)))
            if [[ "${idx}" -ge "${num_verts}" ]]; then 
                echo "  - ERROR: Triangle [${i}] has invalid vertex index [${idx}]!"
                should_fail="1"
            fi
        done
        offset=$((offset + 16))
    done

    # Frames use the same group convention. A simple frame consists of two
    # four-byte trivertx_t bounds, a 16-byte name, and num_verts vertices.
    for ((i=0; i<num_frames; i++)); do
        if ((offset + 4 > file_size)); then
            echo "  - ERROR: Frame [${i}] header extends beyond end of file!"
            return 1
        fi
        group=$(read_int_in_file_at_ofs "${mdl_file}" "${offset}")
        offset=$((offset + 4))

        if [[ "${group}" -eq 0 ]]; then
            record_size=$((24 + num_verts * 4))
        else
            if ((offset + 12 > file_size)); then
                echo "  - ERROR: Frame group [${i}] header extends beyond end of file!"
                return 1
            fi
            group_items=$(read_int_in_file_at_ofs "${mdl_file}" "${offset}")
            if [[ "${group_items}" -le 0 ]]; then
                echo "  - ERROR: Frame group [${i}] has invalid frame count [${group_items}]!"
                return 1
            fi
            offset=$((offset + 12)) # count plus group bounding box
            record_size=$((group_items * 4 + group_items * (24 + num_verts * 4)))
        fi

        if ((offset + record_size > file_size)); then
            echo "  - ERROR: Frame data [${i}] extends beyond end of file [$((offset + record_size)) > ${file_size}]!"
            return 1
        fi
        offset=$((offset + record_size))
    done

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
