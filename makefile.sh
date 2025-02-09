#!/bin/bash

set -e  # Exit immediately on error
set -x  # Print commands for debugging

# Variables
REPO_URL="https://github.com/louij2/distribution-radeon"
REPO_DIR="$HOME/Documents/Repositories/distribution-radeon"
ARCH_CONTAINER_NAME="arch-debug-container"
ARCH_IMAGE="archlinux:latest"
CONTAINER_STORAGE="$HOME/Documents/arch-container-storage"
CONTAINER_OUTPUT="$HOME/Documents/arch-container-output"
PACMAN_CONF_DIR="$HOME/.config/pacman"

# Ensure necessary directories exist
mkdir -p "$CONTAINER_STORAGE" "$CONTAINER_OUTPUT" "$REPO_DIR" "$PACMAN_CONF_DIR"

# Ensure git is installed before cloning
if ! command -v git &>/dev/null; then
    echo "Git is not installed. Installing now..."
    pacman -Sy --noconfirm git
fi

# Clone the repo if it doesn't exist
if [ ! -d "$REPO_DIR/.git" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
else
    cd "$REPO_DIR"
    git pull
fi

# Ensure SteamFork repo configuration exists in pacman
PACMAN_CONF="$PACMAN_CONF_DIR/pacman.conf"
STEAMFORK_MIRRORLIST="$PACMAN_CONF_DIR/steamfork-mirrorlist"

cat > "$STEAMFORK_MIRRORLIST" <<EOF
Server = https://www1.da.steamfork.org/repos/rel
Server = https://www1.sj.steamfork.org/repos/rel
Server = https://www1.as.steamfork.org/repos/rel
Server = https://www1.ny.steamfork.org/repos/rel
Server = https://www.steamfork.org/repos/rel
EOF

cat > "$PACMAN_CONF" <<EOF
[options]
HoldPkg = pacman glibc
Architecture = auto
CheckSpace
SigLevel = Required DatabaseOptional TrustedOnly

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

[steamfork]
Include = $STEAMFORK_MIRRORLIST
EOF

# Run the build process inside the Arch container
docker run --rm -it --privileged \
  -v "$CONTAINER_STORAGE":/mnt/storage \
  -v "$CONTAINER_OUTPUT":/mnt/output \
  -v "$REPO_DIR":/mnt/repositories/distribution-radeon \
  --name "$ARCH_CONTAINER_NAME" "$ARCH_IMAGE" bash -c "
  
  set -e
  echo 'Updating package database...'
  pacman -Sy --noconfirm git base-devel fakeroot archiso

  echo 'Cloning repository inside container...'
  cd /mnt/repositories
  git clone '$REPO_URL' || (cd distribution-radeon && git pull)

  echo 'Setting up pacman...'
  cp /mnt/repositories/distribution-radeon/pacman.conf /etc/pacman.conf
  cp /mnt/repositories/distribution-radeon/steamfork-mirrorlist /etc/pacman.d/steamfork-mirrorlist
  pacman -Sy --noconfirm

  echo 'Starting build process...'
  cd /mnt/repositories/distribution-radeon
  make world
"

echo "Build process completed. Check output in: $CONTAINER_OUTPUT"