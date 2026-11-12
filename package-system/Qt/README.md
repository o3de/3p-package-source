# Qt O3DE 3rd Party Package

## Prerequisites

1. Python 3.10 or newer
1. The Python package `boto3`
1. [3p-package-scripts](https://github.com/o3de/3p-package-scripts) cloned next to [3p-package-source](https://github.com/o3de/3p-package-source)

## Sources and targets

The active Qt 6 packages use the official Qt 6.12.0 source archive:

`https://download.qt.io/official_releases/qt/6.12/6.12.0/single/qt-everywhere-src-6.12.0.tar.xz`

The archive is verified with SHA-1 `1c80692d233922156bcd54ac1ec30099d7245f49`.

| Target | Package |
| --- | --- |
| Windows x64 | `qt-6.12.0-rev2-windows` |
| Linux x86_64 | `qt-6.12.0-rev3-linux` |
| Linux aarch64 | `qt-6.12.0-rev3-linux-aarch64` |
| macOS arm64 | `qt-6.12.0-rev2-mac-arm64` |

## Qt 6 build contents

All active targets build `qtbase`, `qtsvg`, `qtimageformats`, `qttools`, and `qttranslations`. Linux also builds `qtwayland`. QtDeclarative and ActiveQt are explicitly skipped.

The package includes the Qt Widgets libraries used by O3DE, UiTools, `moc`, `uic`, `rcc`, `lupdate`, and `lrelease`. The WebP and TIFF image plugins remain enabled. Qt Widgets Designer, JasPer, MNG, SQL, PrintSupport, and selected unused qttools applications are disabled. DBus and Wayland integration are enabled only for Linux.

Linux and macOS build one Release Qt configuration. Windows builds Debug and `RelWithDebInfo` so O3DE Debug uses ABI-compatible `d`-suffixed Qt libraries and plugins, while Profile and Release use the optimized unsuffixed build.

The Linux builds resolve TIFF, zlib, and OpenSSL through the corresponding architecture-specific O3DE dependency packages and force Qt to use them instead of silently selecting bundled or host-system copies.

Linux uses Qt's bundled JPEG implementation to avoid a dependency on a distribution-specific `libjpeg` ABI. The CMake package requires WaylandClient development dependencies only when `PAL_TRAIT_LINUX_WINDOW_MANAGER_WAYLAND` is enabled. Wayland runtime plugins are deployed for both configurations.

Linux hides symbols from the statically linked zlib archive in Qt libraries and plugins so system libpng cannot mix Qt's private zlib with the system copy.

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
./package.bat build qt-6.12.0-rev2-windows
```

### Linux x86_64

```bash
./package.sh build qt-6.12.0-rev3-linux
```

### Linux aarch64

```bash
./package.sh build qt-6.12.0-rev3-linux-aarch64
```

### macOS arm64

```bash
./package.sh build qt-6.12.0-rev2-mac-arm64
```
