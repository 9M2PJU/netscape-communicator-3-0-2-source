# Netscape Communicator 3.02 for Linux

[![Linux packages](https://github.com/9M2PJU/netscape-communicator-3-02-for-linux/actions/workflows/linux-packages.yml/badge.svg)](https://github.com/9M2PJU/netscape-communicator-3-02-for-linux/actions/workflows/linux-packages.yml)

This repository preserves the Netscape Communicator 3.02 source tree and the
Linux build work needed to compile it with current GCC, glibc, Perl, X11, and
Motif packages.

The source contains the XFE browser, mail client, and news client. The package
build disables the old Java and Mocha components with
`NO_JAVA=1 NO_MOCHA=1`.

GitHub Actions builds native packages for two Linux architectures:

| Format | amd64 / x86-64 | arm64 / AArch64 |
| --- | --- | --- |
| Debian package | `.deb` | `.deb` |
| RPM package | `.rpm` | `.rpm` |
| AppImage | `.AppImage` | `.AppImage` |

## Project Status

This is historical browser software. Its networking code, certificate store,
script engine, rendering code, and file handling do not meet current security
standards. Do not use it for ordinary web browsing or sensitive mail.

The Linux packaging work makes the source build on current 64-bit Linux
systems. It does not update the browser's network protocols, certificate
handling, script engine, renderer, or file handling. Use this project for
source preservation, build experiments, demonstrations, and controlled
testing. Keep it away from sensitive accounts, untrusted web content, and
production mail.

## Quick Start

1. Open the repository's [Releases](https://github.com/9M2PJU/netscape-communicator-3-02-for-linux/releases) page.
2. Download the package that matches your CPU and Linux distribution.
3. Follow the installation command for the package format in
   [Installation](#installation).

Each pushed `v*` tag produces a GitHub Release after both architecture builds
pass. Branch, pull request, and manual workflow runs produce Actions artifacts
instead of releases.

## Contents

- [Downloads](#downloads)
- [Installation](#installation)
- [Build locally](#build-locally)
- [GitHub Actions](#github-actions)
- [Package contents](#package-contents)
- [Repository layout](#repository-layout)
- [Linux compatibility changes](#linux-compatibility-changes)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Contributing](#contributing)

## Downloads

### GitHub Releases

The [Releases](https://github.com/9M2PJU/netscape-communicator-3-02-for-linux/releases) page contains assets from tag builds. Push a tag whose name starts
with `v`, such as `v3.02.2`. The workflow builds both architectures, creates a
GitHub Release, and attaches six files:

| Architecture | Debian package | RPM package | AppImage |
| --- | --- | --- | --- |
| amd64 | `*-linux-amd64.deb` | `*-x86_64.rpm` | `*-linux-amd64.AppImage` |
| arm64 | `*-linux-arm64.deb` | `*-aarch64.rpm` | `*-linux-arm64.AppImage` |

The release job runs after both architecture builds finish. It creates release
notes for a new tag and replaces assets when you rerun a tag workflow.

The Debian and AppImage filenames use `amd64` and `arm64`. RPM filenames use
the RPM names `x86_64` and `aarch64`.

### Actions artifacts

Pushes to `main`, pull requests, and manual workflow runs produce two Actions
artifacts named after the source version and architecture. GitHub retains
these artifacts for 14 days. Tag builds publish the same files to the Release.

## Installation

The packages need an X11 display and Motif runtime libraries. An XWayland
session can provide the X11 display on a Wayland desktop. The CI packages target
Ubuntu 24.04 runtime package names; other distributions may need a rebuild or
manual dependency adjustments.

The one-line commands below install the current `v3.02.2` packaging release for
source version `3.02`. Replace
`amd64` with `arm64` for Debian/AppImage files and replace `x86_64` with
`aarch64` for RPM files on an ARM64 system.

### Arch Linux and CachyOS

The release does not include a native Arch package, so install the AppImage in
your user account:

```sh
mkdir -p "$HOME/.local/bin" && curl -fL "https://github.com/9M2PJU/netscape-communicator-3-02-for-linux/releases/download/v3.02.2/netscape-communicator-3.02-linux-amd64.AppImage" -o "$HOME/.local/bin/netscape-communicator.AppImage" && chmod +x "$HOME/.local/bin/netscape-communicator.AppImage" && APPIMAGE_EXTRACT_AND_RUN=1 "$HOME/.local/bin/netscape-communicator.AppImage"
```

### Debian-based distributions

```sh
curl -fL "https://github.com/9M2PJU/netscape-communicator-3-02-for-linux/releases/download/v3.02.2/netscape-communicator-3.02-linux-amd64.deb" -o /tmp/netscape-communicator-3.02-linux-amd64.deb && sudo apt install -y /tmp/netscape-communicator-3.02-linux-amd64.deb
```

### Debian or Ubuntu

Download the package for your machine, then run:

```sh
sudo apt install ./netscape-communicator-3.02-linux-amd64.deb
netscape
```

Use the `arm64` filename on an ARM64 system.

The generated `.deb` declares Ubuntu 24.04 dependencies, including
`libxt6t64` and `libxm4`. Debian releases that use different package names need
an adapted control file or a local rebuild.

### Ubuntu-based distributions

```sh
curl -fL "https://github.com/9M2PJU/netscape-communicator-3-02-for-linux/releases/download/v3.02.2/netscape-communicator-3.02-linux-amd64.deb" -o /tmp/netscape-communicator-3.02-linux-amd64.deb && sudo apt install -y /tmp/netscape-communicator-3.02-linux-amd64.deb
```

### RPM-based distributions

Fedora, openSUSE, and other RPM-based distributions can install the RPM with
their package manager. For Fedora, run:

```sh
sudo dnf install ./netscape-communicator-3.02-1.x86_64.rpm
netscape
```

Use the `aarch64` RPM on an ARM64 system. `rpm -Uvh` also works when you need a
low-level installation command, but it does not resolve dependencies.

The current RPM spec does not declare runtime `Requires` entries. Install the
Motif and X11 runtime packages provided by your distribution when `dnf` or
another RPM frontend does not pull them in.

### Red Hat-based distributions

```sh
curl -fL "https://github.com/9M2PJU/netscape-communicator-3-02-for-linux/releases/download/v3.02.2/netscape-communicator-3.02-1.x86_64.rpm" -o /tmp/netscape-communicator-3.02-1.x86_64.rpm && sudo dnf install -y /tmp/netscape-communicator-3.02-1.x86_64.rpm
```

### AppImage

Make the file executable and start it:

```sh
chmod +x netscape-communicator-3.02-linux-amd64.AppImage
./netscape-communicator-3.02-linux-amd64.AppImage
```

Set `APPIMAGE_EXTRACT_AND_RUN=1` when the host does not provide FUSE:

```sh
APPIMAGE_EXTRACT_AND_RUN=1 ./netscape-communicator-3.02-linux-amd64.AppImage
```

The AppImage bundles the non-glibc shared libraries discovered from the build,
including the X11 and Motif libraries used by the application. It uses the
host's glibc and X server.

## Build Locally

The CI environment uses Ubuntu 24.04 on native amd64 and arm64 runners. Use a
native Ubuntu 24.04 host for a matching local build. Cross-compilation is not
part of this script.

Install the same build dependencies on Ubuntu 24.04:

```sh
sudo apt-get update
sudo apt-get install --no-install-recommends -y \
  build-essential \
  ca-certificates \
  curl \
  desktop-file-utils \
  dpkg-dev \
  file \
  gawk \
  imagemagick \
  libice-dev \
  libmotif-dev \
  libsm-dev \
  libx11-dev \
  libxext-dev \
  libxmu-dev \
  libxpm-dev \
  libxt-dev \
  patchelf \
  perl \
  rpm \
  squashfs-tools
```

Run the packaging script from the repository root:

```sh
SOURCE_ROOT="$PWD" \
OUTPUT_DIR="$PWD/artifacts" \
BUILD_JOBS=1 \
bash packaging/linux/build-and-package.sh
```

The script builds the source, stages the installed files, and writes packages
to `artifacts/`.

The default source version comes from `cmd/xfe/versionn.h`. You can override
the build settings for a local run:

```sh
VERSION=3.02 \
PACKAGE_NAME=netscape-communicator \
BUILD_JOBS=1 \
bash packaging/linux/build-and-package.sh
```

Set `APPIMAGETOOL` to an executable appimagetool path when you want to use a
local copy. Without that variable, the script downloads the official
architecture-specific tool from the AppImage project.

The script supports the following host architectures:

| Host | Debian | RPM | AppImage tool |
| --- | --- | --- | --- |
| x86-64 | `amd64` | `x86_64` | `x86_64` |
| AArch64 | `arm64` | `aarch64` | `aarch64` |

The build rejects a binary whose architecture does not match the host.

The legacy makefiles write object files, generated headers, and other build
outputs into the source tree, usually under `Linux2.6_OPT.OBJ` and `dist/`.
Set `OUTPUT_DIR` to keep the three distributable files in a separate
directory. The script downloads the architecture-specific `appimagetool` when
`APPIMAGETOOL` is not set, so a local AppImage build needs network access.

Inspect the generated files with the same checks used by CI:

```sh
dpkg-deb -f artifacts/*.deb Package Version Architecture
rpm -qp --qf '%{NAME} %{VERSION}-%{RELEASE} %{ARCH}\n' artifacts/*.rpm
file artifacts/*.AppImage
```

## GitHub Actions

The workflow lives at
`.github/workflows/linux-packages.yml`. It runs for:

- pushes to `main`
- pushes of tags matching `v*`
- pull requests
- manual `workflow_dispatch` runs

The build matrix uses native runners:

| Matrix entry | Runner | Binary architecture |
| --- | --- | --- |
| `amd64` | `ubuntu-24.04` | x86-64 |
| `arm64` | `ubuntu-24.04-arm` | AArch64 |

Each matrix job performs these steps:

1. Install the compiler, X11/Motif headers, packaging tools, ImageMagick, and
   AppImage dependencies.
2. Read the version from `cmd/xfe/versionn.h`.
3. Build the browser and mail client with the portable Linux configuration.
4. Create a `.deb`, `.rpm`, and AppImage.
5. Verify the architecture stored in each package.
6. Upload the three files as an Actions artifact.

For a tag push, the `release` job waits for both matrix jobs. It downloads both
artifacts and creates or updates the GitHub Release named after the tag.

The release job uses the workflow's `GITHUB_TOKEN` with `contents: write`. A
repository or organization policy that blocks workflow release writes will
cause that job to fail even when both package jobs pass.

Create a release from the current source version with:

```sh
git tag -a v3.02.2 -m "Netscape Communicator 3.02.2 Linux packaging"
git push origin v3.02.2
```

The tag must point at a commit that contains the workflow. A manual GitHub
Release created without a tag does not start this workflow.

## Package Contents

The Debian and RPM packages install these main paths. The `movemail` binary and
`Netscape.ad` resource file appear when the corresponding build outputs exist:

```text
/usr/bin/netscape
/usr/bin/netscape-communicator
/usr/lib/netscape-communicator/netscape.bin
/usr/lib/netscape-communicator/movemail
/usr/lib/netscape-communicator/XKeysymDB
/usr/lib/netscape-communicator/Netscape.ad
/usr/share/applications/netscape-communicator.desktop
/usr/share/icons/hicolor/48x48/apps/netscape-communicator.png
```

The `netscape` wrapper sets `XKEYSYMDB`, adds the private application directory
to `PATH`, and launches the browser. The AppImage uses the same wrapper under
its AppDir.

The AppImage also carries `AppRun`, the desktop entry, the application icon,
and the shared libraries copied during packaging.

Netscape stores its user profile under `$HOME/.netscape`, following the
historical Unix build. Back up that directory before testing old profile data.

## Repository Layout

| Path | Contents |
| --- | --- |
| `cmd/xfe/` | X11/Motif frontend, resource inputs, icons, and frontend build rules |
| `nspr/` | Netscape Portable Runtime sources and Linux platform code |
| `lib/` | Browser, layout, image, mail, news, networking, and utility libraries |
| `security/` | Historical certificate, crypto, SSL, and security code |
| `sun-java/` | Original Java sources retained in the source import |
| `mocha/` | Original Mocha scripting sources retained in the source import |
| `jpeg/` | JPEG library sources included by the historical tree |
| `include/` | Shared public and internal headers |
| `config/` | Recursive make configuration and platform detection |
| `dist/` | Generated distribution files and exported headers from a local build |
| `packaging/linux/` | Package staging script, wrapper, desktop file, and RPM spec |
| `.github/workflows/` | GitHub Actions build and release workflow |
| `README.jwz` | Notes about changes in the 3.02 plus S/MIME source branch |

The CI build uses `nspr/`, not the adjacent `nspr-/` copy. The tree also
contains historical platform and localization directories that the Linux
package job does not build.

## Linux Compatibility Changes

The original build expected a 1990s Linux toolchain and filesystem layout. The
current tree includes these Linux fixes:

- fall back to `config/Linux2.6.mk` on current kernel versions
- use current `/usr/include` and Motif library discovery
- compile with `-fcommon` for legacy global definitions
- define 32-bit integer types correctly on 64-bit hosts
- generate 64-bit NSPR headers before the main build
- use the glibc `setjmp` layouts for x86-64 and AArch64 thread contexts
- replace obsolete Linux `socketcall` assembly with libc socket wrappers
- use libc `open()` on AArch64, where glibc does not define `SYS_open`
- link through `-lm` instead of the removed `/usr/lib/libm.a` path
- load Perl helper files relative to their scripts
- handle missing locale-map input during resource generation
- keep generated build scripts executable

These changes keep the historical source behavior while allowing the package
job to use current Ubuntu toolchains.

## Troubleshooting

### `Can't open display`

The application needs an X11 display. Check `DISPLAY`, start an X11 or
XWayland session, and run:

```sh
xdpyinfo >/dev/null
```

### `libXm.so.4` is missing

Install the Motif runtime package from your distribution. Ubuntu 24.04 uses
the `libxm4` package. RPM distributions may use a package named `openmotif` or
`motif`.

### The AppImage does not start

Confirm the file has execute permission. Try the extract-and-run mode shown in
the AppImage installation section. Check that the host provides an X11 display
and a compatible glibc.

### A local build cannot find `dpkg-deb` or `rpmbuild`

Install `dpkg-dev` and `rpm`, or run the build on Ubuntu 24.04. The GitHub
workflow installs both tools before it invokes the packaging script.

### A package has the wrong architecture

Run the packaging script on a native host that matches the desired output.
The script accepts `amd64` and `arm64`, checks the compiled ELF binary, and
stops before packaging a mismatched build.

### The workflow creates artifacts but no Release

A branch, pull request, or manual run creates Actions artifacts. A Release
requires a pushed tag matching `v*`, such as `v3.02.2`. The tag workflow must
finish both architecture jobs before the release job can publish its files.

If a tag run passes both build jobs but the release job fails, check the
repository Actions settings and confirm that workflows may create and write
releases. The workflow requests `contents: write` at the release-job level.

## License

The source tree includes historical Netscape license files under
`l10n/us/xp/`, including `LICENSE-export`. Those files contain the original
Netscape Navigator End User License Agreement and mark the software
"REDISTRIBUTION NOT PERMITTED".

Review the included license files before redistributing source or binary
packages. This README does not grant additional rights.

The source tree also contains third-party components with their own notices.
Check those files before copying individual libraries or tools into another
project.

## Contributing

Keep changes compatible with the old recursive make system. Run the package
workflow when changing build or packaging code. Include the host architecture,
Ubuntu version, command, and first relevant error when reporting a failure.
