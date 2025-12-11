# ==========================================================
# Dockerfile: Persistent Remote Desktop (VNC/noVNC/Tailscale)
# Base OS: Ubuntu 22.04 Jammy Jellyfish (Silent Build)
# ==========================================================
FROM ubuntu:22.04

# Set environment variables
ENV HOME /home/developer
ENV USER developer
ENV DEBIAN_FRONTEND noninteractive

# --- 1. Instalasi Dasar & Desktop (Silent) ---
RUN apt update -qq \
    && apt install -yqq \
        sudo \
        curl \
        wget \
        net-tools \
        dbus-x11 \
        xfce4 xfce4-goodies \
        tigervnc-standalone-server \
        xfonts-base \
        firefox \
        python3 python3-pip git \
        apt-transport-https \
    > /dev/null 2>&1 \
    && rm -rf /var/lib/apt/lists/*

# --- 2. Instalasi noVNC (Silent) ---
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC > /dev/null 2>&1 \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify > /dev/null 2>&1 \
    && pip3 install Pillow > /dev/null 2>&1

# --- 3. Konfigurasi User (Sebagai Root) ---
USER root
# Membuat user dan memastikan izin home directory dasar sudah benar
RUN useradd -m $USER \
    && echo "$USER:passwordku" | chpasswd \
    && adduser $USER sudo \
    && chmod 755 /home/developer

# --- 4. Konfigurasi VNC Startup (Root & chown Fix) ---
# Dijalankan oleh Root untuk mencegah 'Permission denied', lalu kepemilikan dialihkan.
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

# --- 5. Instalasi Tailscale (MODERN & STABIL) ---
USER root
# Pastikan wget diinstal
RUN curl -fsSL https://tailscale.com/install.sh | sudo sh >/dev/null 2>&1
         


# --- 6. Entrypoint Script ---
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 6080

# Beralih ke user non-root sebelum menjalankan ENTRYPOINT
USER $USER

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
