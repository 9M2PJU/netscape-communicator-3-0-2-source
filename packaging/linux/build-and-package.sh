#!/usr/bin/env bash
set -Eeuo pipefail

source_root=${SOURCE_ROOT:-$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
output_dir=${OUTPUT_DIR:-$source_root/artifacts}
package_name=${PACKAGE_NAME:-netscape-communicator}
version=${VERSION:-$(sed -n 's/^#define VERSION_NUMBER[[:space:]]*//p' "$source_root/cmd/xfe/versionn.h" | tr -d '[:space:]')}
objdir=${OBJDIR:-Linux2.6_OPT.OBJ}
build_jobs=${BUILD_JOBS:-1}

if command -v dpkg >/dev/null 2>&1; then
    deb_arch=$(dpkg --print-architecture)
else
    case "$(uname -m)" in
        x86_64) deb_arch=amd64 ;;
        aarch64) deb_arch=arm64 ;;
        *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
    esac
fi

case "$deb_arch" in
    amd64)
        rpm_arch=x86_64
        appimage_arch=x86_64
        expected_machine='x86-64'
        ;;
    arm64)
        rpm_arch=aarch64
        appimage_arch=aarch64
        expected_machine='aarch64'
        ;;
    *)
        echo "This packaging workflow supports amd64 and arm64, got $deb_arch" >&2
        exit 1
        ;;
esac

binary="$source_root/cmd/xfe/$objdir/netscape-export"
movemail="$source_root/cmd/xfe/GNU_movemail/$objdir/movemail"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/netscape-package.XXXXXXXX")
stage="$work_dir/root"
appdir="$work_dir/AppDir"
rpm_top="$work_dir/rpm"

cleanup() {
    rm -rf "$work_dir"
}
trap cleanup EXIT

mkdir -p "$output_dir"

echo "Building $package_name $version for $deb_arch"

# The old recursive makefiles are intentionally run serially.  Several
# library/header exports predate parallel make dependency declarations.
make -C "$source_root" \
    BUILD_OPT=1 NO_JAVA=1 NO_MOCHA=1 \
    NSDISTMODE=copy \
    MOTIFLIB="${MOTIFLIB:--lXm}" XINC="${XINC:-/usr/include}" \
    -j1 config

# Refresh generated headers before the main tree consumes the checked-in
# Linux2.6 dist headers.  This is especially important for 64-bit NSPR.
make -C "$source_root/include" \
    BUILD_OPT=1 NO_JAVA=1 NO_MOCHA=1 NSDISTMODE=copy \
    MOTIFLIB="${MOTIFLIB:--lXm}" XINC="${XINC:-/usr/include}" export
make -C "$source_root/nspr/include" \
    BUILD_OPT=1 NO_JAVA=1 NO_MOCHA=1 NSDISTMODE=copy \
    MOTIFLIB="${MOTIFLIB:--lXm}" XINC="${XINC:-/usr/include}" export
make -C "$source_root/nspr/src" \
    BUILD_OPT=1 NO_JAVA=1 NO_MOCHA=1 NSDISTMODE=copy \
    MOTIFLIB="${MOTIFLIB:--lXm}" XINC="${XINC:-/usr/include}" export

make -C "$source_root" \
    BUILD_OPT=1 NO_JAVA=1 NO_MOCHA=1 NSDISTMODE=copy \
    MOTIFLIB="${MOTIFLIB:--lXm}" XINC="${XINC:-/usr/include}" \
    -j"$build_jobs" export all

if [ ! -f "$binary" ]; then
    echo "Build completed without producing $binary" >&2
    exit 1
fi

file_output=$(file -b "$binary")
echo "$file_output"
case "$file_output" in
    *"$expected_machine"*) ;;
    *)
        echo "Built binary has the wrong architecture; expected $expected_machine" >&2
        exit 1
        ;;
esac

rm -rf "$stage" "$appdir" "$rpm_top"
mkdir -p \
    "$stage/usr/bin" \
    "$stage/usr/lib/$package_name" \
    "$stage/usr/share/applications" \
    "$stage/usr/share/doc/$package_name" \
    "$stage/usr/share/icons/hicolor/48x48/apps"

install -m 0755 "$binary" "$stage/usr/lib/$package_name/netscape.bin"
if [ -f "$movemail" ]; then
    install -m 0755 "$movemail" "$stage/usr/lib/$package_name/movemail"
fi
install -m 0644 "$source_root/cmd/xfe/XKeysymDB" \
    "$stage/usr/lib/$package_name/XKeysymDB"
install -m 0644 "$source_root/l10n/us/xp/LICENSE-export" \
    "$stage/usr/share/doc/$package_name/LICENSE"
install -m 0644 "$source_root/cmd/xfe/$objdir/Netscape-export.ad" \
    "$stage/usr/lib/$package_name/Netscape.ad" 2>/dev/null || true
install -m 0755 "$(dirname -- "${BASH_SOURCE[0]}")/netscape-wrapper" \
    "$stage/usr/bin/netscape"
ln -s netscape "$stage/usr/bin/netscape-communicator"
install -m 0644 "$(dirname -- "${BASH_SOURCE[0]}")/netscape.desktop" \
    "$stage/usr/share/applications/netscape-communicator.desktop"

if command -v convert >/dev/null 2>&1; then
    convert "$source_root/cmd/xfe/icons/app.gif" -resize 48x48 \
        "$stage/usr/share/icons/hicolor/48x48/apps/netscape-communicator.png"
elif command -v magick >/dev/null 2>&1; then
    magick "$source_root/cmd/xfe/icons/app.gif" -resize 48x48 \
        "$stage/usr/share/icons/hicolor/48x48/apps/netscape-communicator.png"
else
    echo "ImageMagick is required to create the desktop icon" >&2
    exit 1
fi

if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate "$stage/usr/share/applications/netscape-communicator.desktop"
fi

# AppImage keeps the X/Motif libraries that are not part of the base C
# runtime beside the executable.  The binary and copied libraries share an
# $ORIGIN RPATH, while glibc remains supplied by the host system.
copy_appimage_dependencies() {
    local dep line soname path base
    mkdir -p "$appdir/usr/lib/$package_name"
    while IFS= read -r line; do
        soname=${line%% => *}
        path=${line##* => }
        # ldd appends the mapped address after each resolved library path.
        path=${path%% \(*}
        case "$path" in
            /*) ;;
            *) continue ;;
        esac
        base=${soname##*/}
        case "$base" in
            linux-vdso*|ld-linux*|libc.so*|libm.so*|libpthread.so*|libdl.so*|librt.so*|libresolv.so*|libutil.so*|libgcc_s.so*)
                continue
                ;;
        esac
        if [ -f "$path" ]; then
            cp -L "$path" "$appdir/usr/lib/$package_name/$base"
        fi
    done < <(ldd "$binary" 2>/dev/null || true)

    if ! find "$appdir/usr/lib/$package_name" -maxdepth 1 -type f \
        -name 'lib*.so*' -print -quit | grep -q .; then
        echo "AppImage dependency bundling produced no shared libraries" >&2
        exit 1
    fi

    if command -v patchelf >/dev/null 2>&1; then
        patchelf --set-rpath '$ORIGIN' "$appdir/usr/lib/$package_name/netscape.bin"
        for dep in "$appdir/usr/lib/$package_name"/*; do
            if file -b "$dep" | grep -q ELF; then
                patchelf --set-rpath '$ORIGIN' "$dep" || true
            fi
        done
    fi
}

mkdir -p "$appdir"
cp -a "$stage/." "$appdir/"
# appimagetool discovers the application metadata from the AppDir root,
# while desktop packages keep the same file under /usr/share/applications.
install -m 0644 "$stage/usr/share/applications/netscape-communicator.desktop" \
    "$appdir/netscape-communicator.desktop"
install -m 0644 \
    "$stage/usr/share/icons/hicolor/48x48/apps/netscape-communicator.png" \
    "$appdir/netscape-communicator.png"
copy_appimage_dependencies
install -m 0755 "$(dirname -- "${BASH_SOURCE[0]}")/AppRun" "$appdir/AppRun"

deb_dir="$work_dir/deb"
mkdir -p "$deb_dir/DEBIAN"
cp -a "$stage/." "$deb_dir/"
cat > "$deb_dir/DEBIAN/control" <<EOF
Package: $package_name
Version: $version
Section: web
Priority: optional
Architecture: $deb_arch
Maintainer: Netscape Communicator maintainers <noreply@example.invalid>
Depends: libc6, libice6, libsm6, libx11-6, libxext6, libxmu6, libxpm4, libxt6t64, libxm4
Description: Classic Netscape Communicator X11 browser and mail client
 Netscape Communicator 3.02 packaged from the historical X11/Motif source tree.
EOF
dpkg-deb --build --root-owner-group "$deb_dir" \
    "$output_dir/${package_name}-${version}-linux-$deb_arch.deb"

mkdir -p "$rpm_top/SPECS" "$rpm_top/SOURCES" "$rpm_top/BUILD" \
    "$rpm_top/BUILDROOT" "$rpm_top/RPMS" "$rpm_top/SRPMS"
cp -a "$stage" "$rpm_top/SOURCES/root"
sed -e "s/@VERSION@/$version/g" -e "s/@RPM_ARCH@/$rpm_arch/g" \
    "$(dirname -- "${BASH_SOURCE[0]}")/netscape-communicator.spec.in" \
    > "$rpm_top/SPECS/$package_name.spec"
rpmbuild --define "_topdir $rpm_top" --define "_build_id_links none" \
    -bb "$rpm_top/SPECS/$package_name.spec"
find "$rpm_top/RPMS" -type f -name '*.rpm' -exec cp -f {} "$output_dir/" \;

appimage_tool=${APPIMAGETOOL:-$work_dir/appimagetool}
if [ ! -x "$appimage_tool" ]; then
    curl --fail --location --retry 3 --silent --show-error \
        "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${appimage_arch}.AppImage" \
        --output "$appimage_tool"
    chmod 0755 "$appimage_tool"
fi
APPIMAGE_EXTRACT_AND_RUN=1 "$appimage_tool" "$appdir" \
    "$output_dir/${package_name}-${version}-linux-$deb_arch.AppImage"

chmod -R a+rX "$output_dir"
echo "Artifacts:"
find "$output_dir" -maxdepth 1 -type f -printf '%f\n' | sort
