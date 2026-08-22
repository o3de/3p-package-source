#!/usr/bin/env python3

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

"""
Sign and verify all Mach-O code below a package directory.

The default identity (``-``) creates ad-hoc signatures, which are required for locally built code on Apple silicon.
Release automation can provide a Developer ID Application identity through ``3PS_MACOS_CODE_SIGN_IDENTITY``.
When a real identity is used, signatures include a secure timestamp and hardened runtime.
"""

from __future__ import annotations

import argparse
import os
import pathlib
import re
import subprocess
import sys


MACHO_MAGICS = {
    b"\xfe\xed\xfa\xce",  # MH_MAGIC
    b"\xce\xfa\xed\xfe",  # MH_CIGAM
    b"\xfe\xed\xfa\xcf",  # MH_MAGIC_64
    b"\xcf\xfa\xed\xfe",  # MH_CIGAM_64
    b"\xca\xfe\xba\xbe",  # FAT_MAGIC
    b"\xbe\xba\xfe\xca",  # FAT_CIGAM
    b"\xca\xfe\xba\xbf",  # FAT_MAGIC_64
    b"\xbf\xba\xfe\xca",  # FAT_CIGAM_64
}


def run(command: list[str]) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, check=True)


def is_macho(path: pathlib.Path) -> bool:
    if path.is_symlink() or not path.is_file():
        return False
    try:
        with path.open("rb") as source:
            return source.read(4) in MACHO_MAGICS
    except OSError:
        return False


def is_executable_macho(path: pathlib.Path) -> bool:
    result = subprocess.run(
        ["/usr/bin/otool", "-hv", str(path)],
        check=True,
        capture_output=True,
        text=True,
    )
    return re.search(r"\bEXECUTE\b", result.stdout) is not None


def code_paths(root: pathlib.Path) -> tuple[list[pathlib.Path], list[pathlib.Path]]:
    macho_files = sorted(
        (path for path in root.rglob("*") if is_macho(path)),
        key=lambda path: (len(path.parts), str(path)),
        reverse=True,
    )
    bundles = sorted(
        (
            path
            for path in root.rglob("*")
            if path.is_dir() and path.suffix in {".app", ".bundle", ".framework"}
        ),
        key=lambda path: (len(path.parts), str(path)),
        reverse=True,
    )
    if root.is_dir() and root.suffix in {".app", ".bundle", ".framework"}:
        bundles.append(root)
    return macho_files, bundles


def sign_path(
    path: pathlib.Path,
    identity: str,
    entitlements: pathlib.Path | None,
    executable: bool,
) -> None:
    # Some universal binaries contain a linker signature in only one slice.
    # codesign --force rejects that mixed state, so normalize every Mach-O to
    # unsigned before applying the package signature.
    if path.is_file():
        run(["/usr/bin/codesign", "--remove-signature", str(path)])

    command = ["/usr/bin/codesign", "--force", "--sign", identity]
    if identity != "-":
        command.extend(["--timestamp", "--options", "runtime"])
        if executable and entitlements:
            command.extend(["--entitlements", str(entitlements)])
    command.append(str(path))
    run(command)


def verify_path(path: pathlib.Path, deep: bool = False) -> None:
    command = ["/usr/bin/codesign", "--verify", "--strict", "--verbose=2"]
    if deep:
        command.append("--deep")
    command.append(str(path))
    run(command)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=pathlib.Path, help="Package directory to sign")
    parser.add_argument(
        "--identity",
        default=os.environ.get("O3DE_MACOS_CODE_SIGN_IDENTITY") or "-",
        help="codesign identity; defaults to O3DE_MACOS_CODE_SIGN_IDENTITY or ad-hoc '-'",
    )
    parser.add_argument(
        "--entitlements",
        type=pathlib.Path,
        help="Entitlements applied to Mach-O executables for Developer ID signing",
    )
    args = parser.parse_args()

    if sys.platform != "darwin":
        parser.error("macOS code signing must run on macOS")

    root = args.root.resolve(strict=True)
    entitlements = args.entitlements.resolve(strict=True) if args.entitlements else None
    macho_files, bundles = code_paths(root)
    if not macho_files:
        parser.error(f"no Mach-O files found below {root}")

    for path in macho_files:
        sign_path(path, args.identity, entitlements, is_executable_macho(path))
    for path in bundles:
        sign_path(path, args.identity, None, False)

    for path in macho_files:
        verify_path(path)
    for path in bundles:
        verify_path(path, deep=True)

    print(f"Signed and verified {len(macho_files)} Mach-O files below {root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
