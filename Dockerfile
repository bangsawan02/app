# ==========================================================
# Dockerfile: Persistent Remote Desktop (VNC/noVNC/Tailscale)
# Base OS: Ubuntu 22.04 Jammy Jellyfish (Menyamakan dengan ubuntu-latest runner)
# ==========================================================
FROM ubuntu:22.04

# Set environment variables
ENV HOME /home/developer
ENV USER developer
ENV DEBIAN_FRONTEND noninteractive

# --- 1. Instalasi Dasar & Desktop ---
RUN apt update -qq \
    # Menggunakan -yqq untuk instalasi silent (quiet)
    && apt install -yqq \
        sudo \
        wget \
        net-tools \
        dbus-x11 \
        # Xfce Desktop Environment
        xfce4 xfce4-goodies \
        # TigerVNC Server
        tigervnc-standalone-server \
        xfonts-base \
        firefox \
        # Paket yang diperlukan untuk noVNC/Websockify
        python3 python3-pip git \
        # Instalasi Tailscale
        apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# --- 2. Instalasi noVNC ---
# Catatan: Ubuntu 22.04 menggunakan python3/pip3 secara default.
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify \
    && pip3 install Pillow

# --- 3. Konfigurasi User (Sebagai Root) ---
USER root
RUN useradd -m $USER \
    && echo "$USER:passwordku" | chpasswd \
    && adduser $USER sudo \
    && chmod 755 /home/developer

# --- 4. Konfigurasi VNC Startup (DIJALANKAN SEBAGAI ROOT, Izin Diberikan) ---
RUN mkdir -p /home/developer/.vnc \
    && echo '#!/bin/bash' > /home/developer/.vnc/xstartup \
    && echo 'unset SESSION_MANAGER' >> /home/developer/.vnc/xstartup \
    && echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /home/developer/.vnc/xstartup \
    && echo 'startxfce4 &' >> /home/developer/.vnc/xstartup \
    && chmod +x /home/developer/.vnc/xstartup \
    \
    && echo "vncpwd" | vncpasswd -f > /home/developer/.vnc/passwd \
    \
    && chown -R $USER:$USER /home/developer/.vnc \
    && chmod 700 /home/developer/.vnc \
    && chmod 600 /home/developer/.vnc/passwd

# --- 5. Instalasi Tailscale ---
USER root
# Pastikan Anda menggunakan list Tailscale untuk Jammy (22.04)
RUN curl -fsSL https://pkgs.tailscale.com/ubuntu/KEY.gpg | sudo apt-key add - \
    && curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.list | sudo tee /etc/apt/sources.list.d/tailscale.list \
    && apt update -qq \
    && apt install -yqq tailscale

# --- 6. Entrypoint Script ---
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 6080

USER $USER

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
