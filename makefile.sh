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
pacman -Sy --noconfirm base-devel git sudo fakeroot archiso gnupg

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

# Set up SteamFork repository and required SteamOS repositories
echo "Configuring pacman with SteamFork and SteamOS repositories..."
cat > "$PACMAN_CONF" <<EOF
[options]
HoldPkg = pacman glibc
Architecture = auto
CheckSpace
ParallelDownloads = 5
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional

[steamfork]
Include = /etc/pacman.d/steamfork-mirrorlist

[jupiter-main]
Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch
SigLevel = Never

[holo-main]
Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch
SigLevel = Never

[core-main]
Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch
SigLevel = Never

[extra-main]
Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch
SigLevel = Never

[community-main]
Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch
SigLevel = Never

[multilib-main]
Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch
SigLevel = Never
EOF

# Set up SteamFork mirrorlist
cat > "$STEAMFORK_MIRRORLIST" <<EOF
Server = https://www1.da.steamfork.org/repos/rel
Server = https://www1.sj.steamfork.org/repos/rel
Server = https://www1.as.steamfork.org/repos/rel
Server = https://www1.ny.steamfork.org/repos/rel
Server = https://www.steamfork.org/repos/rel
EOF

# Initialize and refresh PGP keys
echo "Initializing pacman keyring..."
pacman-key --init
pacman-key --populate archlinux

# Import and trust the SteamFork PGP key
echo "Importing SteamFork PGP key..."
pacman-key --recv-keys A33991EE2981A3B05368EF5E75C1E5647441B94C
echo "Trusting SteamFork PGP key..."
echo "5" | pacman-key --edit-key A33991EE2981A3B05368EF5E75C1E5647441B94C trust
pacman-key --lsign-key A33991EE2981A3B05368EF5E75C1E5647441B94C

# Sync pacman databases again to include all new repositories
echo "Updating pacman after adding all repositories..."
pacman -Sy --noconfirm

# Change directory to repo
cd "$REPO_DIR"

# Start the build process
echo "Starting build process..."
make world

echo "Build completed successfully."