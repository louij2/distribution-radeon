#!/bin/bash

set -e  # Exit immediately on error
set -x  # Print commands for debugging

# Variables
REPO_URL="https://github.com/louij2/distribution-radeon"
REPO_DIR="/mnt/repositories/distribution-radeon"
PACMAN_CONF="/etc/pacman.conf"
STEAMFORK_MIRRORLIST="/etc/pacman.d/steamfork-mirrorlist"

# Ensure system is up to date
echo "Updating system..."
pacman -Sy --noconfirm pacman-mirrorlist reflector base-devel git sudo fakeroot archiso

# Clone the repository if it doesn't exist
if [ ! -d "$REPO_DIR/.git" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
else
    cd "$REPO_DIR"
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

cat >> "$PACMAN_CONF" <<EOF

[steamfork]
Include = /etc/pacman.d/steamfork-mirrorlist
EOF

# Sync package databases
echo "Updating pacman..."
pacman -Sy --noconfirm

# Install required dependencies
echo "Installing dependencies..."
pacman -S --noconfirm base-devel git sudo fakeroot archiso

# Change directory to repo
cd "$REPO_DIR"

# Start the build process
echo "Starting build process..."
make world

echo "Build completed successfully."