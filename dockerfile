# Use the official Arch Linux image
FROM archlinux:latest

# Set up environment
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm-256color

# Install necessary packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git archiso sudo curl

# Add the SteamFork repository to pacman.conf
RUN echo "[steamfork]" >> /etc/pacman.conf && \
    echo "Include = /etc/pacman.d/steamfork-mirrorlist" >> /etc/pacman.conf

# Add the SteamFork mirror list
RUN cat <<EOF > /etc/pacman.d/steamfork-mirrorlist
Server = https://www1.da.steamfork.org/repos/rel
Server = https://www1.sj.steamfork.org/repos/rel
Server = https://www1.as.steamfork.org/repos/rel
Server = https://www1.ny.steamfork.org/repos/rel
Server = https://www.steamfork.org/repos/rel
EOF

# Sync pacman and install the SteamFork keyring
RUN pacman -Syy --noconfirm && \
    pacman -S steamfork-keyring --noconfirm

# Manually trust the SteamFork key
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman-key --lsign-key A33991EE2981A3B05368EF5E75C1E5647441B94C

# Install additional SteamFork packages (if needed)
RUN pacman -S --noconfirm steamfork-installer steamfork-customizations steamfork-device-support

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