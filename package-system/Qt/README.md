# Qt O3DE 3rd Party Package

## Prerequisites

1. Python 3.10 or newer
1. The Python package `boto3`
1. [3p-package-scripts](https://github.com/o3de/3p-package-scripts) cloned next to [3p-package-source](https://github.com/o3de/3p-package-source)

## Sources and targets

The active Qt 6 packages use the official Qt 6.12.1 source archive:

`https://download.qt.io/official_releases/qt/6.12/6.12.1/single/qt-everywhere-src-6.12.1.tar.xz`

The archive is verified with SHA-1 `b54cabfd36c67f95f4578f5fe24deb9d7a78ccd4`.

| Target | Package |
| --- | --- |
| Windows x64 | `qt-6.12.1-rev1-windows` |
| Linux x86_64 | `qt-6.12.1-rev1-linux` |
| Linux aarch64 | `qt-6.12.1-rev1-linux-aarch64` |
| macOS arm64 | `qt-6.12.1-rev1-mac-arm64` |

## Qt 6 build contents

All active targets build `qtbase`, `qtimageformats`, `qtlanguageserver`, `qtsvg`, `qttools`, `qttranslations`, and `qtwebsockets`. Linux also builds `qtwayland`. QtDeclarative and ActiveQt are explicitly skipped.

The package includes the Qt Widgets libraries used by O3DE, UiTools, `moc`, `uic`, `rcc`, `lupdate`, and `lrelease`. The WebP and TIFF image plugins remain enabled. Qt Widgets Designer, JasPer, MNG, SQL, PrintSupport, and selected unused qttools applications are disabled. DBus and Wayland integration are enabled only for Linux.

Linux and macOS build one Release Qt configuration. Windows builds Debug and `RelWithDebInfo` so O3DE Debug uses ABI-compatible `d`-suffixed Qt libraries and plugins, while Profile and Release use the optimized unsuffixed build.

All targets use Qt's bundled libtiff and zlib.

Linux uses Qt's bundled JPEG implementation to avoid a dependency on a distribution-specific `libjpeg` ABI. The CMake package requires WaylandClient development dependencies only when `PAL_TRAIT_LINUX_WINDOW_MANAGER_WAYLAND` is enabled. Wayland runtime plugins are deployed for both configurations.

Qt prefixes its bundled zlib symbols so system libpng binds to the system zlib on Linux.

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
./package.bat build qt-6.12.1-rev1-windows
```

### Linux x86_64

```bash
./package.sh build qt-6.12.1-rev1-linux
```

### Linux aarch64

```bash
./package.sh build qt-6.12.1-rev1-linux-aarch64
```

### macOS arm64

```bash
./package.sh build qt-6.12.1-rev1-mac-arm64
```
