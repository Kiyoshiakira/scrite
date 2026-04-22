#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERSION="${VERSION:-$(sed -n 's/^VERSION[[:space:]]*=[[:space:]]*//p' "${REPO_ROOT}/scrite.pro" | head -n 1)}"
APPDIR_NAME="Scrite-${VERSION}.AppImage"
APPDIR_PATH="${SCRIPT_DIR}/${APPDIR_NAME}"
LINUXDEPLOYQT_BIN="${LINUXDEPLOYQT:-${HOME}/linuxdeployqt}"

rm -rf "${APPDIR_PATH}"
mkdir -p "${APPDIR_PATH}/bin" "${APPDIR_PATH}/lib"

cp "${REPO_ROOT}/../Release/Scrite" "${APPDIR_PATH}/bin/"
cp /usr/lib/x86_64-linux-gnu/libssl.so.1.1 "${APPDIR_PATH}/lib"
cp /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 "${APPDIR_PATH}/lib"
cp -L /usr/lib/x86_64-linux-gnu/libibus-1.0.so "${APPDIR_PATH}/lib"
cp -L /usr/lib/x86_64-linux-gnu/libgio-2.0.so "${APPDIR_PATH}/lib"
cp -L /usr/lib/x86_64-linux-gnu/libgobject-2.0.so "${APPDIR_PATH}/lib"
cp -L /usr/lib/x86_64-linux-gnu/libglib-2.0.so "${APPDIR_PATH}/lib"
chmod a-x "${APPDIR_PATH}"/lib/*.so*

mkdir -p "${APPDIR_PATH}/share/applications"
cp "${SCRIPT_DIR}/Scrite.desktop" "${APPDIR_PATH}/share/applications/Scrite.desktop"
mkdir -p "${APPDIR_PATH}/share/icons/hicolor/512x512/apps/"
cp "${REPO_ROOT}/images/appicon.png" "${APPDIR_PATH}/share/icons/hicolor/512x512/apps/Scrite.png"
mkdir -p "${APPDIR_PATH}/share/icons/hicolor/256x256/apps/"
convert "${REPO_ROOT}/images/appicon.png" -resize 256x256 "${APPDIR_PATH}/share/icons/hicolor/256x256/apps/Scrite.png"

"${LINUXDEPLOYQT_BIN}" "${APPDIR_PATH}/share/applications/Scrite.desktop" -appimage -qmldir="${REPO_ROOT}/qml" -verbose=2 -no-translations -no-copy-copyright-files
