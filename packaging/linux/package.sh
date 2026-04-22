#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERSION="${VERSION:-$(awk -F'=' '/^VERSION[[:space:]]*=/{gsub(/^[\"'\''[:space:]]+|[\"'\''[:space:]]+$/, "", $2); print $2; exit}' "${REPO_ROOT}/scrite.pro")}"
APPDIR_NAME="Scrite-${VERSION}.AppDir"
APPDIR_PATH="${SCRIPT_DIR}/${APPDIR_NAME}"
APPIMAGE_OUTPUT_PATH="${SCRIPT_DIR}/Scrite-${VERSION}-x86_64.AppImage"
LINUXDEPLOYQT_BIN="${LINUXDEPLOYQT:-${HOME}/linuxdeployqt}"
SCRITE_BINARY_PATH="${SCRITE_BINARY_PATH:-${REPO_ROOT}/../Release/Scrite}"
LIB_DIR="/usr/lib/x86_64-linux-gnu"
QMAKE_BIN="${QMAKE_BIN:-$(command -v qmake || true)}"
QT_QML_DIR=""

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

if [[ -n "${QMAKE_BIN}" ]]; then
    QT_QML_DIR="$("${QMAKE_BIN}" -query QT_INSTALL_QML 2>/dev/null || true)"
fi

if [[ -z "${QT_QML_DIR}" ]]; then
    for candidate in \
        /usr/lib/x86_64-linux-gnu/qt5/qml \
        /usr/lib/qt5/qml; do
        if [[ -d "${candidate}" ]]; then
            QT_QML_DIR="${candidate}"
            break
        fi
    done
fi

if [[ -z "${QT_QML_DIR}" || ! -d "${QT_QML_DIR}" ]]; then
    echo "ERROR: Unable to locate Qt QML install directory" >&2
    exit 1
fi

rm -rf "${APPDIR_PATH}"
mkdir -p "${APPDIR_PATH}/bin" "${APPDIR_PATH}/lib" "${APPDIR_PATH}/qml"

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
cp -a "${REPO_ROOT}/qml/." "${APPDIR_PATH}/qml/"

mkdir -p "${APPDIR_PATH}/share/applications"
cp "${SCRIPT_DIR}/Scrite.desktop" "${APPDIR_PATH}/share/applications/Scrite.desktop"
mkdir -p "${APPDIR_PATH}/share/icons/hicolor/512x512/apps/"
cp "${REPO_ROOT}/images/appicon.png" "${APPDIR_PATH}/share/icons/hicolor/512x512/apps/Scrite.png"
mkdir -p "${APPDIR_PATH}/share/icons/hicolor/256x256/apps/"
convert "${REPO_ROOT}/images/appicon.png" -resize 256x256 "${APPDIR_PATH}/share/icons/hicolor/256x256/apps/Scrite.png"

"${LINUXDEPLOYQT_BIN}" "${APPDIR_PATH}/share/applications/Scrite.desktop" -qmldir="${REPO_ROOT}/qml" -verbose=2 -no-translations -no-copy-copyright-files

for module in \
    QtQml \
    QtQml/Models.2 \
    QtQuick \
    QtQuick.2 \
    QtQuick/Controls.2 \
    QtQuick/Layouts \
    QtQuick/Templates.2 \
    QtQuick/Window.2; do
    if [[ -d "${QT_QML_DIR}/${module}" ]]; then
        mkdir -p "$(dirname "${APPDIR_PATH}/qml/${module}")"
        if [[ -d "${APPDIR_PATH}/qml/${module}" ]]; then
            cp -a "${QT_QML_DIR}/${module}/." "${APPDIR_PATH}/qml/${module}/"
        else
            cp -a "${QT_QML_DIR}/${module}" "${APPDIR_PATH}/qml/${module}"
        fi
    fi
done

cat > "${APPDIR_PATH}/AppRun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APPDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export QML2_IMPORT_PATH="${APPDIR}/qml:${APPDIR}/usr/qml${QML2_IMPORT_PATH:+:${QML2_IMPORT_PATH}}"
export QT_PLUGIN_PATH="${APPDIR}/plugins:${APPDIR}/usr/plugins${QT_PLUGIN_PATH:+:${QT_PLUGIN_PATH}}"
export QT_QPA_PLATFORM_PLUGIN_PATH="${APPDIR}/plugins/platforms:${APPDIR}/usr/plugins/platforms${QT_QPA_PLATFORM_PLUGIN_PATH:+:${QT_QPA_PLATFORM_PLUGIN_PATH}}"

# Prevent host GIO/GVFS modules from being loaded against AppImage-bundled GLib.
export GIO_MODULE_DIR=/nonexistent
export GIO_EXTRA_MODULES=/nonexistent

SCRITE_BIN="${APPDIR}/bin/Scrite"
if [[ ! -x "${SCRITE_BIN}" ]]; then
    SCRITE_BIN="${APPDIR}/usr/bin/Scrite"
fi

exec "${SCRITE_BIN}" "$@"
EOF
chmod +x "${APPDIR_PATH}/AppRun"

APPIMAGETOOL_BIN="${APPIMAGETOOL:-$(command -v appimagetool || true)}"
if [[ -z "${APPIMAGETOOL_BIN}" ]]; then
    APPIMAGETOOL_TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "${APPIMAGETOOL_TMP_DIR}"' EXIT
    (
        cd "${APPIMAGETOOL_TMP_DIR}"
        "${LINUXDEPLOYQT_BIN}" --appimage-extract >/dev/null
    )
    APPIMAGETOOL_BIN="${APPIMAGETOOL_TMP_DIR}/squashfs-root/usr/bin/appimagetool"
fi

if [[ ! -x "${APPIMAGETOOL_BIN}" ]]; then
    echo "ERROR: appimagetool executable not found" >&2
    exit 1
fi

rm -f "${APPIMAGE_OUTPUT_PATH}"
ARCH=x86_64 "${APPIMAGETOOL_BIN}" "${APPDIR_PATH}" "${APPIMAGE_OUTPUT_PATH}"
