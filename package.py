#!/usr/bin/env python3
"""Simple package helper: list and build stubs for package-system packages.

Usage:
  python build_package.py list
  python build_package.py build <package-name>

This script is intentionally lightweight: `list` shows packages under
`package-system/`. `build` shows available build scripts for a package.
"""
from __future__ import annotations

import argparse
import ssl
import sys
import json
import certifi
import urllib.request
from pathlib import Path
from typing import List
import platform

PACKAGING_SCRIPT_PATH = Path(__file__).parent / "Scripts" / "packaging" / "o3de_package_scripts"
sys.path.append(str(PACKAGING_SCRIPT_PATH))

from build_package import BuildPackage

HOST_PLATFORM = platform.system()
if HOST_PLATFORM == "Windows":
    PACKAGE_BUILD_LIST_PLATFORM_ARCH = 'windows'
elif HOST_PLATFORM == "Linux":
    PACKAGE_BUILD_LIST_PLATFORM_ARCH = 'linux'
elif HOST_PLATFORM == "Darwin":
    PACKAGE_BUILD_LIST_PLATFORM_ARCH = 'darwin'
else:
    print("Unsupported platform:", HOST_PLATFORM)
    sys.exit(1)

PACKAGE_BUILD_LIST_FILE = Path(__file__).parent / f"package_build_list_host_{PACKAGE_BUILD_LIST_PLATFORM_ARCH}.json"
with PACKAGE_BUILD_LIST_FILE.open() as f:
    PACKAGE_BUILD_CONFIG = json.load(f)

REMOTE_CACHE_FILE = Path(__file__).parent / ".remote_cache.json"
if REMOTE_CACHE_FILE.is_file():
    with REMOTE_CACHE_FILE.open() as f:
        try:
            REMOTE_CACHE = json.load(f)
        except json.JSONDecodeError:
            REMOTE_CACHE = {}
else:
    REMOTE_CACHE = {}

# ANSI color escape sequences
GREEN = "\033[32m"
RED = "\033[31m"
LIGHT_GREY = "\033[90m"
RESET = "\033[0m"

DEFAULT_LY_PACKAGE_SERVER_URLS = ["https://d3t6xeg4fgfoum.cloudfront.net"]

def get_remote_package_hash(package_name: str, package_server_urls: str = DEFAULT_LY_PACKAGE_SERVER_URLS) -> str:
    cached_package_hashes = REMOTE_CACHE if REMOTE_CACHE else {}
    if package_name in cached_package_hashes:
        return cached_package_hashes[package_name]
    
    for server_url in package_server_urls:
        tls_context = ssl.create_default_context(cafile=certifi.where())
        full_package_url = f"{server_url}/{package_name}.tar.xz.SHA256SUMS"
        try:
            with urllib.request.urlopen(url=full_package_url, context=tls_context) as server_response:
                file_data = server_response.read()
                str_data = file_data.decode("utf-8", errors="ignore")
                hash_and_name = str_data.split()
                if hash_and_name:
                    cached_package_hashes[package_name] = hash_and_name[0]
                return hash_and_name[0] if hash_and_name else ""
        except Exception:
            continue
    return ""

class PackageInfo:
    def __init__(self, name: str, folder: str, hash_info: str, fixed: bool, valid: bool):
        self.name = name
        self.folder = folder
        self.hash_info = hash_info
        self.fixed = fixed
        self.valid = valid

def list_packages() -> int:

    global REMOTE_CACHE
    cache_updated = False

    # First iterate over the keys and values from 'build_from_folder'
    build_from_folder = PACKAGE_BUILD_CONFIG.get("build_from_folder", "package-system")
    build_from_source = PACKAGE_BUILD_CONFIG.get("build_from_source", "package-source")

    packages_list = []

    for package_name, folder in build_from_folder.items():

        if package_name in REMOTE_CACHE:
            prod_hash = REMOTE_CACHE[package_name]
        else:
            prod_hash = get_remote_package_hash(package_name)
            if prod_hash:
                REMOTE_CACHE[package_name] = prod_hash
                cache_updated = True

        # Package in build_from_folder must match directory in build_from_source otherwise its a fixed package
        if package_name in build_from_source:
            package = PackageInfo(name=package_name,
                                  folder=build_from_source[package_name],
                                  hash_info=prod_hash,
                                  fixed=False,
                                  valid=True)
        else:
            # This is a fixed package, need to validate if that folder exists
            if (Path(__file__).parent / folder).is_dir():
                package = PackageInfo(name=package_name,
                                      folder=folder,
                                      hash_info=prod_hash,
                                      fixed=True,
                                      valid=True)
            else:
                package = PackageInfo(name=package_name,
                                      folder=folder,
                                      hash_info=prod_hash,
                                      fixed=True,
                                      valid=False)
        packages_list.append(package)

    max_width = 0
    for package in packages_list:
        if len(package.name) > max_width:
            max_width = len(package.name)

    # Print header
    print(f"\n{'Package Name':<{max_width}} {'Hash Info':<64} {'Type':<20}")
    print("-" * (max_width + 84))
    
    # Print each package
    for package in packages_list:

        if package.fixed:
            type_info = "Fixed"
        else:
            if 'pull_and_build_from_git.py' in package.folder:
                type_info = "Pull and build from Git"
            else:
                type_info = "Custom Build Script"
        
        if package.valid:
            print(f"{LIGHT_GREY}{package.name:<{max_width}} {package.hash_info:<64} {type_info:<20}{RESET}")
        else:
            print(f"{RED}{package.name:<{max_width}} {package.hash_info:<64} {type_info:<20}{RESET}")

    if cache_updated:
        with REMOTE_CACHE_FILE.open("w") as cache_file:
            json.dump(REMOTE_CACHE, fp=cache_file)
    
    return 0


def build_package(name: str) -> int:
    output_folder = Path(__file__).parent / "packages"
    search_path = Path(__file__).parent
    BuildPackage(name, output_folder, search_path)
    return 0

def main(argv: List[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    parser = argparse.ArgumentParser(prog="build_package.py", description="List and inspect package build scripts")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("list", help="List packages in package-system/")

    b = sub.add_parser("build", help="Show build scripts for a package")
    b.add_argument("package", help="Package name (directory under package-system)")

    args = parser.parse_args(argv)

    if args.command == "list":
        return list_packages()
    if args.command == "build":
        return build_package(args.package)
    parser.print_help()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
