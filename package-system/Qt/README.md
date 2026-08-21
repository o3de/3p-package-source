# Qt O3DE 3rd Party Package

## Prerequisites

1. Python 3.10 or newer
1. The Python package `boto3`
1. [3p-package-scripts](https://github.com/o3de/3p-package-scripts) cloned next to [3p-package-source](https://github.com/o3de/3p-package-source)

## Sources and targets

The active Qt 6 packages use the official Qt 6.11.2 source archive:

`https://download.qt.io/official_releases/qt/6.11/6.11.2/single/qt-everywhere-src-6.11.2.tar.xz`

The archive is verified with SHA-1 `7e15dbb24d8d390b04fb53bb7397a2f625608132`.

| Target | Package |
| --- | --- |
| Windows x64 | `qt-6.11.2-rev1-windows` |
| Linux x86_64 | `qt-6.11.2-rev1-linux` |
| macOS arm64 | `qt-6.11.2-rev1-mac-arm64` |
| macOS Intel (legacy) | `qt-5.15.2-rev8-mac` |
| Linux aarch64 (legacy) | `qt-5.15.2-rev10-linux-aarch64` |

The legacy Qt 5 targets continue to use the O3DE Qt git repository.

## Qt 6 build contents

All active targets build `qtbase`, `qtsvg`, `qtimageformats`, `qttools`, and `qttranslations`. Linux also builds `qtwayland`. QtDeclarative and ActiveQt are explicitly skipped.

The package includes the Qt Widgets libraries used by O3DE, UiTools, `moc`, `uic`, `rcc`, `lupdate`, and `lrelease`. The WebP and TIFF image plugins remain enabled. Qt Widgets Designer, JasPer, MNG, SQL, PrintSupport, and selected unused qttools applications are disabled. DBus and Wayland integration are enabled only for Linux.

The Linux x86_64 build resolves TIFF, zlib, and OpenSSL through the corresponding O3DE dependency packages and forces Qt to use them instead of silently selecting bundled or host-system copies.

QtCanvasPainter is not included. Its open-source licensing and dependency on QtDeclarative are incompatible with this package configuration.

## Updating

When changing build inputs without changing the Qt release, increment the platform-specific revision. When changing the upstream Qt release, update:

- `src_package_url`, `src_package_sha1`, and `package_version` in `build_config.json`
- The archive source paths in the active platform build scripts and `recursion-check.patch`
- The forced Qt version in `FindQt.cmake`
- The matching keys in each active host package build list

Package names follow `qt-${package_version}-${platform}`.

## Building

Run these commands from the `3p-package-source` repository. Adjust the relative `3p-package-scripts` path if the repositories are laid out differently.

### Windows x64

```bat
python ..\3p-package-scripts\o3de_package_scripts\build_package.py --search_path . qt-6.11.2-rev1-windows
```

### Linux x86_64

```bash
python3 ../3p-package-scripts/o3de_package_scripts/build_package.py --search_path . qt-6.11.2-rev1-linux
```

### macOS arm64

```bash
python3 ../3p-package-scripts/o3de_package_scripts/build_package.py --search_path . qt-6.11.2-rev1-mac-arm64
```

### Legacy targets

```bash
python3 ../3p-package-scripts/o3de_package_scripts/build_package.py --search_path . qt-5.15.2-rev8-mac
python3 ../3p-package-scripts/o3de_package_scripts/build_package.py --search_path . qt-5.15.2-rev10-linux-aarch64
```
