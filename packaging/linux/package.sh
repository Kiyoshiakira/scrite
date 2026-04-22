#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERSION="${VERSION:-$(awk -F'=' '/^VERSION[[:space:]]*=/{gsub(/^[\"'\''[:space:]]+|[\"'\''[:space:]]+$/, "", $2); print $2; exit}' "${REPO_ROOT}/scrite.pro")}"
APPDIR_NAME="Scrite-${VERSION}.AppImage"
APPDIR_PATH="${SCRIPT_DIR}/${APPDIR_NAME}"
LINUXDEPLOYQT_BIN="${LINUXDEPLOYQT:-${HOME}/linuxdeployqt}"
SCRITE_BINARY_PATH="${SCRITE_BINARY_PATH:-${REPO_ROOT}/../Release/Scrite}"
LIB_DIR="/usr/lib/x86_64-linux-gnu"

if [[ -z "${VERSION}" ]]; then
    echo "ERROR: Unable to determine Scrite VERSION from ${REPO_ROOT}/scrite.pro" >&2
    exit 1
fi

if [[ ! -x "${SCRITE_BINARY_PATH}" ]]; then
    echo "ERROR: Scrite binary not found or not executable at ${SCRITE_BINARY_PATH}" >&2
    exit 1
fi

if [[ ! -x "${LINUXDEPLOYQT_BIN}" ]]; then
    echo "ERROR: linuxdeployqt executable not found at ${LINUXDEPLOYQT_BIN}" >&2
    exit 1
fi

rm -rf "${APPDIR_PATH}"
mkdir -p "${APPDIR_PATH}/bin" "${APPDIR_PATH}/lib"

cp "${SCRITE_BINARY_PATH}" "${APPDIR_PATH}/bin/"
for lib in \
    libssl.so.1.1 \
    libcrypto.so.1.1 \
    libibus-1.0.so \
    libgio-2.0.so \
    libgobject-2.0.so \
    libglib-2.0.so; do
    cp -L "${LIB_DIR}/${lib}" "${APPDIR_PATH}/lib"
done
chmod a-x "${APPDIR_PATH}"/lib/*.so*

mkdir -p "${APPDIR_PATH}/share/applications"
cp "${SCRIPT_DIR}/Scrite.desktop" "${APPDIR_PATH}/share/applications/Scrite.desktop"
mkdir -p "${APPDIR_PATH}/share/icons/hicolor/512x512/apps/"
cp "${REPO_ROOT}/images/appicon.png" "${APPDIR_PATH}/share/icons/hicolor/512x512/apps/Scrite.png"
mkdir -p "${APPDIR_PATH}/share/icons/hicolor/256x256/apps/"
convert "${REPO_ROOT}/images/appicon.png" -resize 256x256 "${APPDIR_PATH}/share/icons/hicolor/256x256/apps/Scrite.png"

"${LINUXDEPLOYQT_BIN}" "${APPDIR_PATH}/share/applications/Scrite.desktop" -appimage -qmldir="${REPO_ROOT}/qml" -verbose=2 -no-translations -no-copy-copyright-files
