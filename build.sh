#!/usr/bin/env bash
# Build Scrite on Ubuntu 24.04 or later.
# Run from the repository root:  bash build.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${REPO_ROOT}/build"
RELEASE_DIR="${REPO_ROOT}/../Release"

echo "==> Installing build dependencies (requires sudo)..."
sudo apt-get update
sudo apt-get install -y \
    build-essential pkg-config \
    qt5-qmake qtbase5-dev qtbase5-dev-tools qtdeclarative5-dev \
    qtquickcontrols2-5-dev qttools5-dev qttools5-dev-tools \
    qtmultimedia5-dev libqt5svg5-dev libqt5charts5-dev qtwebengine5-dev \
    libhunspell-dev libibus-1.0-dev ibus imagemagick libssl-dev \
    libxcb-cursor0 libxcb-xinerama0

echo "==> Configuring build in shadow directory: ${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"
qmake "${REPO_ROOT}/scrite.pro" CONFIG+=release

echo "==> Building (using $(nproc) parallel jobs)..."
make -j"$(nproc)"

SCRITE_BINARY="${RELEASE_DIR}/Scrite"
if [[ -x "${SCRITE_BINARY}" ]]; then
    echo ""
    echo "Build complete. Binary: ${SCRITE_BINARY}"
else
    echo "ERROR: Expected binary not found at ${SCRITE_BINARY}" >&2
    exit 1
fi
