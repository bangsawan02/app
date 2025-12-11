# ==========================================================
# Dockerfile: Persistent Remote Desktop (VNC/noVNC/Tailscale)
# Base OS: Ubuntu 18.04 Bionic (Plucky)
# ==========================================================
FROM ubuntu:18.04

# Set environment variables
ENV HOME /home/developer
ENV USER developer
ENV DEBIAN_FRONTEND noninteractive

# --- 1. Instalasi Dasar & Desktop (Termasuk Paket noVNC dan Dependensi) ---
RUN apt update \
    # Upgrade dan instal alat dasar
    && apt install -y \
        sudo \
        wget \
        net-tools \
        dbus-x11 \
        # Xfce Desktop Environment
        xfce4 xfce4-goodies \
        # TigerVNC Server
        tigervnc-standalone-server \
        # Font dasar
        xfonts-base \
        firefox \
        # Paket yang diperlukan untuk noVNC/Websockify
        python python-pip git \
        # Instalasi Tailscale
        apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# --- 2. Instalasi noVNC ---
# Kloning repositori noVNC ke direktori /opt
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify \
    && pip install Pillow

# --- 3. Konfigurasi User ---
# Buat user baru 'developer' dan tambahkan ke grup sudo
RUN useradd -m $USER \
    && echo "$USER:passwordku" | chpasswd \
    && adduser $USER sudo

# Ganti ke user non-root untuk konfigurasi VNC
USER $USER
WORKDIR $HOME

# --- 4. Konfigurasi VNC Startup (Perbaikan Error $HOME) ---
# 🔥 Menggunakan path absolut /home/developer untuk memastikan RUN berhasil 🔥
RUN mkdir -p /home/developer/.vnc \
    && echo '#!/bin/bash' > /home/developer/.vnc/xstartup \
    && echo 'unset SESSION_MANAGER' >> /home/developer/.vnc/xstartup \
    && echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /home/developer/.vnc/xstartup \
    && echo 'startxfce4 &' >> /home/developer/.vnc/xstartup \
    && chmod +x /home/developer/.vnc/xstartup

# Tetapkan sandi VNC (digunakan untuk otentikasi VNC)
RUN echo "vncpwd" | vncpasswd -f > /home/developer/.vnc/passwd \
    && chmod 600 /home/developer/.vnc/passwd

# --- 5. Instalasi Tailscale (Kembali ke Root) ---
USER root
RUN curl -fsSL https://pkgs.tailscale.com/ubuntu/KEY.gpg | sudo apt-key add - \
    && curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/bionic.list | sudo tee /etc/apt/sources.list.d/tailscale.list \
    && apt update \
    && apt install -y tailscale

# --- 6. Entrypoint Script ---
# Entrypoint akan memulai Tailscale, VNC, dan noVNC
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Port noVNC standar (untuk akses web)
EXPOSE 6080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
