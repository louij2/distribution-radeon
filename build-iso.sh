#!/bin/bash

# Ensure script isn't run as root initially
if [ $EUID -eq 0 ]; then
    echo "❌ Please run this script without sudo. The script will prompt for elevated permissions when needed."
    exit 1
fi

# Prompt for Git repository URL
read -p "🔗 Enter the Git repository URL to clone: " GIT_REPO_URL
GIT_REPO_URL=${GIT_REPO_URL:-https://github.com/SteamFork/distribution.git}

# Default clone directory (can be customized)
read -p "📁 Enter the directory to clone into (default: ~/steamfork-build): " CLONE_DIR
CLONE_DIR=${CLONE_DIR:-~/steamfork-build}

# Clone the repository
if [ -d "${CLONE_DIR}" ]; then
    echo "📥 Directory already exists. Pulling the latest changes..."
    cd "${CLONE_DIR}" && git pull
else
    echo "🚀 Cloning repository..."
    git clone "${GIT_REPO_URL}" "${CLONE_DIR}"
fi

# Navigate to the working directory
cd "${CLONE_DIR}" || { echo "❌ Failed to enter directory. Exiting."; exit 1; }

# Initialize submodules if needed
git submodule update --init --recursive

# Build the SteamFork ISO
echo "📦 Building SteamFork ISO..."
make image minimal || { echo "⚠️ Minimal ISO build failed."; exit 1; }
make image rel || { echo "⚠️ Release ISO build failed."; exit 1; }

# Locate the built ISO
ISO_FILE_PATH=$(find "${CLONE_DIR}/release/images" -name "*.iso" | head -n 1)
if [ -z "$ISO_FILE_PATH" ]; then
    echo "❌ ISO build failed or ISO not found."
    exit 1
fi

# Generate checksums and metadata
ISO_FILE_NAME=$(basename "${ISO_FILE_PATH}")
VERSION=$(echo "${ISO_FILE_NAME}" | cut -c11-20 | sed 's/\./-/g')
ID=$(git rev-parse --short HEAD)

# Generate checksum
pushd "$(dirname "${ISO_FILE_PATH}")" > /dev/null
sha256sum "${ISO_FILE_NAME}" > sha256sum.txt
cat sha256sum.txt
popd > /dev/null

# Output build information
echo "✅ Build complete. ISO Name: ${ISO_FILE_NAME}"
echo "🔖 Version: ${VERSION}"
echo "🔑 Commit ID: ${ID}"