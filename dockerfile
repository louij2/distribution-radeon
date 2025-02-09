# Use the official Arch Linux image
FROM archlinux:latest

# Set up environment
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm-256color

# Fix missing locale issue
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Install necessary packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git archiso sudo curl gnupg fakeroot

# Add SteamFork and SteamOS repositories to pacman.conf (EXCLUDING broken HoloISO repos)
RUN echo "[steamfork]" >> /etc/pacman.conf && \
    echo "Include = /etc/pacman.d/steamfork-mirrorlist" >> /etc/pacman.conf && \
    echo "[jupiter-main]" >> /etc/pacman.conf && \
    echo "Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch" >> /etc/pacman.conf && \
    echo "SigLevel = Never" >> /etc/pacman.conf && \
    echo "[holo-main]" >> /etc/pacman.conf && \
    echo "Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch" >> /etc/pacman.conf && \
    echo "SigLevel = Never" >> /etc/pacman.conf && \
    echo "[core-main]" >> /etc/pacman.conf && \
    echo "Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch" >> /etc/pacman.conf && \
    echo "SigLevel = Never" >> /etc/pacman.conf && \
    echo "[extra-main]" >> /etc/pacman.conf && \
    echo "Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch" >> /etc/pacman.conf && \
    echo "SigLevel = Never" >> /etc/pacman.conf && \
    echo "[community-main]" >> /etc/pacman.conf && \
    echo "Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch" >> /etc/pacman.conf && \
    echo "SigLevel = Never" >> /etc/pacman.conf && \
    echo "[multilib-main]" >> /etc/pacman.conf && \
    echo "Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/\$repo/os/\$arch" >> /etc/pacman.conf && \
    echo "SigLevel = Never" >> /etc/pacman.conf

# Add the SteamFork mirror list
RUN cat <<EOF > /etc/pacman.d/steamfork-mirrorlist
Server = https://www1.da.steamfork.org/repos/rel
Server = https://www1.sj.steamfork.org/repos/rel
Server = https://www1.as.steamfork.org/repos/rel
Server = https://www1.ny.steamfork.org/repos/rel
Server = https://www.steamfork.org/repos/rel
EOF

# 🔹 Manually import and trust the SteamFork key before installing the keyring
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman-key --recv-key A33991EE2981A3B05368EF5E75C1E5647441B94C --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key A33991EE2981A3B05368EF5E75C1E5647441B94C

# 🔹 Install SteamFork keyring and packages
RUN pacman -Syy --noconfirm && \
    pacman -S steamfork-keyring --noconfirm && \
    pacman -S --noconfirm steamfork-installer steamfork-customizations steamfork-device-support

# 🔹 Manually install `aurutils` from AUR (since it is not in pacman)
RUN git clone https://aur.archlinux.org/aurutils.git /tmp/aurutils && \
    cd /tmp/aurutils && \
    makepkg -si --noconfirm && \
    rm -rf /tmp/aurutils

# 🔹 Install all required packages from Makefile
RUN pacman -S --noconfirm \
    linux-firmware linux python-strictyaml python-sphinx-hawkmoth \
    libdrm lib32-libdrm libglvnd lib32-libglvnd wayland lib32-wayland wayland-protocols \
    xorg-xwayland mesa mesa-radv lib32-mesa lib32-mesa-radv gamescope gamescope-legacy \
    ectool steam-powerbuttond steamfork-customizations steamfork-device-support steamfork-installer \
    webrtc-audio-processing inputplumber ryzenadj pikaur grafana-alloy

# 🔹 Install AUR packages using aurutils
RUN aur sync -c -n --noview wlr-randr dnsmasq-git libglibutil libgbinder python-gbinder waydroid xone-dongle-firmware xone-dkms

# Create build directories (where the Makefile expects them)
RUN mkdir -p /rootfs/installer /rootfs/steamfork /scripts /_work /release/images /release/repos

# Clone the custom repo directly into where `BUILD_DIR` expects it
RUN git clone https://github.com/louij2/distribution-radeon.git /rootfs/steamfork

# Ensure correct permissions for the build
RUN chmod -R 777 /rootfs/steamfork

# Set the default working directory to where the repo is cloned
WORKDIR /rootfs/steamfork

# Set the default command to start a bash shell
CMD ["/usr/bin/bash"]