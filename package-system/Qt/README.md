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
| Linux aarch64 | `qt-6.11.2-rev1-linux-aarch64` |
| macOS arm64 | `qt-6.11.2-rev1-mac-arm64` |

## Qt 6 build contents

All active targets build `qtbase`, `qtsvg`, `qtimageformats`, `qttools`, and `qttranslations`. Linux also builds `qtwayland`. QtDeclarative and ActiveQt are explicitly skipped.

The package includes the Qt Widgets libraries used by O3DE, UiTools, `moc`, `uic`, `rcc`, `lupdate`, and `lrelease`. The WebP and TIFF image plugins remain enabled. Qt Widgets Designer, JasPer, MNG, SQL, PrintSupport, and selected unused qttools applications are disabled. DBus and Wayland integration are enabled only for Linux.

Linux and macOS build one Release Qt configuration. Windows builds Debug and `RelWithDebInfo` so O3DE Debug uses ABI-compatible `d`-suffixed Qt libraries and plugins, while Profile and Release use the optimized unsuffixed build.

The Linux builds resolve TIFF, zlib, and OpenSSL through the corresponding architecture-specific O3DE dependency packages and force Qt to use them instead of silently selecting bundled or host-system copies.

QtCanvasPainter is not included. Its open-source licensing and dependency on QtDeclarative are incompatible with this package configuration.

## Updating

When changing build inputs without changing the Qt release, increment the package revision. When changing the upstream Qt release, update:

- `src_package_url`, `src_package_sha1`, and `package_version` in `build_config.json`
- The forced Qt version in `FindQt.cmake`
- The matching keys in each host package build list

Package names follow `qt-${package_version}-${platform}`.

## Building

Run these commands from the `3p-package-source` repository.

### Windows x64

```bat
./package.bat build qt-6.11.2-rev1-windows
```

### Linux x86_64

```bash
./package.sh build qt-6.11.2-rev1-linux
```

### Linux aarch64

```bash
./package.sh build qt-6.11.2-rev1-linux-aarch64
```

### macOS arm64

```bash
./package.sh build qt-6.11.2-rev1-mac-arm64
```
