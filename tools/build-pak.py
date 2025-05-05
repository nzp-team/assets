#!/usr/bin/python3

import os
import sys
import argparse

MAX_NAME_LENGTH = 56
pak_entries = []

def parse_args() -> argparse.Namespace:
    """
    Collect our arguments
    """

    parser = argparse.ArgumentParser()
    parser.add_argument(
            "--input",
            "-i",
            type=str,
            dest="assets_path", 
            help="Directory of assembled NZP assets",
            required=True)

    parser.add_argument(
            "--output",
            "-o",
            type=str,
            dest="output_path", 
            help="Location to store output PAK file",
            required=True)

    parser.add_argument(
            "--verbose",
            "-v",
            dest="verbose", 
            help="Increase verbosity",
            action="store_true")

    args = parser.parse_args()

    if not os.path.isdir(args.assets_path):
        raise Exception(f"Assets directory does not exist: {assets_path}")

    return args

def write_data(assets_path: str, output_path: str, verbose=False) -> None:
    """
    Write data from our pak_entries into our output file

    Based off of the C implementation brought to you by ChatGPT :(
    """

    with open(output_path, "wb") as output_pak_file:
        # Reserve space for header
        output_pak_file.write(b'\x00' * 12)

        # Write file data and store offsets
        for entry in pak_entries:
            entry["offset"] = output_pak_file.tell()
            file_path = os.path.join(assets_path, entry["name"])

            with open(file_path, "rb") as datafile: output_pak_file.write(datafile.read())

        # Build our directory LUT
        dir_offset = output_pak_file.tell()
        for entry in pak_entries:
            if (verbose):
                print("Info: Writing entry to file")
                print(entry)
            output_pak_file.write(entry["name"].encode("ascii").ljust(56, b'\x00'))
            output_pak_file.write(entry["offset"].to_bytes(4, byteorder="little"))
            output_pak_file.write(entry["size"].to_bytes(4, byteorder="little"))
        dir_length = output_pak_file.tell() - dir_offset

        # Write the header 
        output_pak_file.seek(0)
        output_pak_file.write(b'PACK')
        output_pak_file.write(dir_offset.to_bytes(4, byteorder="little"))
        output_pak_file.write(dir_length.to_bytes(4, byteorder="little"))



def collect_files(assets_path, rel_path="", verbose=False):
    """
    Recursively determine our list of files to include in a PAK and 
    denote their information. Store results to pak_entries

    This is done recursively since we want to always populate subdirectories prior to 
    files in the current directory? Or at least was the need in NSPIRE
    """

    new_path = os.path.join(assets_path, rel_path)

    # Find files in our directory
    for entry in sorted(os.listdir(new_path)):

        # Determine their new subpath
        new_rel = os.path.join(rel_path, entry)
        full_path = os.path.join(assets_path, new_rel)

        # If a directory, we need to navigate it first
        if os.path.isdir(full_path):
            collect_files(assets_path, new_rel)
        elif os.path.isfile(full_path):
            size = os.path.getsize(full_path)

            pak_name = new_rel.encode("ascii")
            if len(pak_name) > MAX_NAME_LENGTH:
                raise Exception(f"File {pak_name} has length > {MAX_NAME_LENGTH}")

            pak_entry = {
                "name": new_rel,
                "size": size
            }

            pak_entries.append(pak_entry)

            if (verbose):
                print(pak_entry)

def main():
    """
    main function. Build a PAK
    """
    args = parse_args()

    if not os.path.isdir(args.assets_path):
        raise Exception(f"{args.assets_path} is not a directory or does not exist!")

    # Collect our entries and write to pak_entries
    collect_files(args.assets_path, "", args.verbose)
    write_data(args.assets_path, args.output_path, args.verbose)

    print(f"Info: Write PAK file to {args.output_path}")

if __name__ == "__main__":
    main()