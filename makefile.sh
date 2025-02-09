#!/bin/bash

set -e  # Exit immediately on error
set -x  # Print commands for debugging

# Variables
REPO_URL="https://github.com/louij2/distribution-radeon"
REPO_DIR="/mnt/repositories/distribution-radeon"
PACMAN_CONF="/etc/pacman.conf"
STEAMFORK_MIRRORLIST="/etc/pacman.d/steamfork-mirrorlist"

# Manually update mirrorlist to avoid slow mirrors
echo "Updating pacman mirrors..."
cat > /etc/pacman.d/mirrorlist <<EOF
Server = https://mirror.osbeck.com/archlinux/\$repo/os/\$arch
Server = https://mirror.cyberbits.eu/archlinux/\$repo/os/\$arch
Server = https://archlinux.uk.mirror.allworldit.com/archlinux/\$repo/os/\$arch
Server = https://mirror.netcologne.de/archlinux/\$repo/os/\$arch
EOF

# Ensure system is up to date
echo "Updating system..."
pacman -Syyu --noconfirm || echo "Ignoring upgrade errors..."

# Install essential dependencies
echo "Installing essential packages..."
pacman -Sy --noconfirm base-devel git sudo fakeroot archiso

# Ensure repository directory exists
mkdir -p "$REPO_DIR"

# Clone or update the repository
if [ ! -d "$REPO_DIR/.git" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
else
    cd "$REPO_DIR"
    git config --global --add safe.directory "$REPO_DIR"  # Fix "dubious ownership"
    git pull
fi

# Set up SteamFork repository
echo "Configuring pacman with SteamFork mirrors..."
cat > "$STEAMFORK_MIRRORLIST" <<EOF
Server = https://www1.da.steamfork.org/repos/rel
Server = https://www1.sj.steamfork.org/repos/rel
Server = https://www1.as.steamfork.org/repos/rel
Server = https://www1.ny.steamfork.org/repos/rel
Server = https://www.steamfork.org/repos/rel
EOF

if ! grep -q "\[steamfork\]" "$PACMAN_CONF"; then
    echo -e "\n[steamfork]\nInclude = /etc/pacman.d/steamfork-mirrorlist" >> "$PACMAN_CONF"
fi

# Sync pacman databases again to include SteamFork repo
echo "Updating pacman after adding SteamFork repo..."
pacman -Sy --noconfirm

# Change directory to repo
cd "$REPO_DIR"

# Start the build process
echo "Starting build process..."
make world

echo "Build completed successfully."