# ==========================================================
# Dockerfile: Persistent Remote Desktop (VNC/noVNC/Tailscale)
# Base OS: Ubuntu 18.04 Bionic (Plucky)
# ==========================================================
FROM ubuntu:18.04

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
        python python-pip git \
        # Instalasi Tailscale
        apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# --- 2. Instalasi noVNC ---
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify \
    && pip install Pillow

# --- 3. Konfigurasi User (Sebagai Root) ---
# Buat user baru 'developer' dan tambahkan ke grup sudo
USER root
RUN useradd -m $USER \
    && echo "$USER:passwordku" | chpasswd \
    && adduser $USER sudo

# --- 4. Konfigurasi VNC Startup (Dijalankan sebagai Root, Izin Disetel) ---
# Menggunakan path absolut dan chown untuk mengatasi masalah 'Permission denied'
RUN mkdir -p /home/developer/.vnc \
    && echo '#!/bin/bash' > /home/developer/.vnc/xstartup \
    && echo 'unset SESSION_MANAGER' >> /home/developer/.vnc/xstartup \
    && echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /home/developer/.vnc/xstartup \
    && echo 'startxfce4 &' >> /home/developer/.vnc/xstartup \
    && chmod +x /home/developer/.vnc/xstartup \
    && chown -R $USER:$USER /home/developer/.vnc \
    && chmod 700 /home/developer/.vnc

# Tetapkan sandi VNC (Dijalankan sebagai user 'developer' melalui su -c)
RUN echo "vncpwd" | su $USER -c "vncpasswd -f > /home/developer/.vnc/passwd" \
    && chown $USER:$USER /home/developer/.vnc/passwd \
    && chmod 600 /home/developer/.vnc/passwd

# --- 5. Instalasi Tailscale ---
USER root
RUN curl -fsSL https://pkgs.tailscale.com/ubuntu/KEY.gpg | sudo apt-key add - \
    && curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/bionic.list | sudo tee /etc/apt/sources.list.d/tailscale.list \
    && apt update -qq \
    && apt install -yqq tailscale

# --- 6. Entrypoint Script ---
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Port noVNC standar (untuk akses web)
EXPOSE 6080

# Beralih ke user non-root (developer) sebelum menjalankan ENTRYPOINT
# Ini penting agar VNC dan Xfce berjalan dengan izin yang benar
USER $USER

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
