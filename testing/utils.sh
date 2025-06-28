#
# Nazi Zombies: Portable
# Utility script used by asset testing
#

#
# is_pow2()
# ----
# Basic Power-of-Two test function
#
function is_pow2()
{
    local n=$1
    (( n > 0 )) && (( (n & (n - 1)) == 0 ))
}

#
# read_int_in_file_at_ofs()
# ----
# Read LE 4-byte int from input file
#
function read_int_in_file_at_ofs()
{
    local input="${1}"
    local ofs="${2}"
    dd if="${1}" bs=1 skip=${ofs} count=4 2>/dev/null | od -An -t u4 | awk '{print $1}'
}

#
# read_float_in_file_at_ofs()
# ----
# Read LE 4-byte float from input file
#
read_float_in_file_at_ofs()
{
    local input="${1}"
    local ofs="${2}"
    dd if="${1}" bs=1 skip=${ofs} count=4 2>/dev/null | od -An -t f4 | awk '{print $1}'
}

#
# read_short_in_file_at_ofs()
# ----
# Read LE 2-byte short from input file
#
read_short_in_file_at_ofs()
{
    local input="${1}"
    local ofs="${2}"
    dd if="${input}" bs=1 skip="${ofs}" count=2 2>/dev/null | od -An -t u2 | awk '{print $1}'
}

#
# read_string_in_file_at_ofs()
# ----
# Read ASCII string from input file
#
read_string_in_file_at_ofs()
{
    local input="${1}"
    local strlen="${2}"
    local ofs="${3}"
    dd if="${1}" bs=1 skip=${ofs} count=${strlen} 2>/dev/null | xxd -p -c4 | xxd -r -p
}

#
# read_byte_in_file_at_ofs()
# ----
# Read byte from input file
#
read_byte_in_file_at_ofs()
{
    local input="${1}"
    local ofs="${2}"
    dd if="${input}" bs=1 skip="${ofs}" count=1 2>/dev/null | od -An -t u1 | awk '{print $1}'
}