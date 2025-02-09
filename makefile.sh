#!/bin/bash

set -e  # Exit on first error
set -x  # Debugging enabled

AUR_PACKAGES=("wlr-randr" "dnsmasq-git" "libglibutil" "libgbinder" "python-gbinder" "waydroid" "xone-dongle-firmware" "xone-dkms")
PACMAN_CONF_PATH="/etc/aurutils/pacman-x86_64.conf"
LOGFILE="/var/log/aur_install.log"

# Function to create pacman-x86_64.conf if missing
fix_pacman_conf() {
    echo "🔹 Creating missing /etc/aurutils/pacman-x86_64.conf..."
    cat <<EOF > $PACMAN_CONF_PATH
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
    echo "✅ Pacman config created."
}

# Function to install AUR packages using aurutils
install_aur_packages() {
    echo "🚀 Attempting AUR installation using aurutils..."

    # First attempt: Normal `aur sync -c`
    if su builder -c "aur sync -c -n --noview ${AUR_PACKAGES[*]}"; then
        echo "✅ AUR packages installed successfully!"
        return 0
    else
        echo "⚠️ aur sync -c failed! Checking for missing pacman config..."
    fi

    # Second attempt: Fix missing pacman.conf and retry
    if [ ! -f "$PACMAN_CONF_PATH" ]; then
        fix_pacman_conf
    fi

    echo "🔄 Retrying AUR installation after fixing pacman.conf..."
    if su builder -c "aur sync -c -n --noview ${AUR_PACKAGES[*]}"; then
        echo "✅ AUR packages installed successfully after fixing pacman.conf!"
        return 0
    else
        echo "⚠️ aur sync -c still failed! Trying aur build instead..."
    fi

    # Final attempt: Switch to `aur build`
    if su builder -c "aur build -d steamfork ${AUR_PACKAGES[*]}"; then
        echo "✅ AUR packages installed using aur build!"
        return 0
    else
        echo "❌ All AUR installation methods failed! Logging errors..."
        echo "AUR installation failed at $(date)" >> $LOGFILE
        return 1
    fi
}

# Run the installation function
install_aur_packages