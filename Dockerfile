# Gunakan Ubuntu Bionic (18.04) sebagai base image
FROM ubuntu:18.04

# Set environment variables
ENV HOME /home/developer
ENV USER developer
ENV DEBIAN_FRONTEND noninteractive

# --- 1. Instalasi Dasar & Desktop (Tambahkan Paket noVNC) ---
RUN apt update \
    && apt install -y \
        sudo \
        wget \
        net-tools \
        dbus-x11 \
        xfce4 xfce4-goodies \
        # Menggunakan TigerVNC
        tigervnc-standalone-server \
        xfonts-base \
        firefox \
        # 🔥 Paket yang diperlukan untuk noVNC (websockify dan git) 🔥
        python python-pip git \
        # Instal Tailscale
        apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# --- 2. Instalasi noVNC ---
# Kloning repositori noVNC ke direktori
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify \
    && pip install Pillow

# --- 3. Konfigurasi User dan VNC Startup (Sama seperti sebelumnya) ---
RUN useradd -m $USER \
    && echo "$USER:passwordku" | chpasswd \
    && adduser $USER sudo

USER $USER
WORKDIR $HOME

# Konfigurasi VNC Startup: Xfce
RUN mkdir -p $HOME/.vnc \
    && echo '#!/bin/bash' > $HOME/.vnc/xstartup \
    && echo 'unset SESSION_MANAGER' >> $HOME/.vnc/xstartup \
    && echo 'unset DBUS_SESSION_BUS_ADDRESS' >> $HOME/.vnc/xstartup \
    && echo 'startxfce4 &' >> $HOME/.vnc/xstartup \
    && chmod +x $HOME/.vnc/xstartup

# Tetapkan sandi VNC (hanya untuk server VNC, bukan noVNC/Web)
RUN echo "vncpwd" | vncpasswd -f > $HOME/.vnc/passwd \
    && chmod 600 $HOME/.vnc/passwd

# --- 4. Instalasi Tailscale ---
USER root
RUN curl -fsSL https://pkgs.tailscale.com/ubuntu/KEY.gpg | sudo apt-key add - \
    && curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/bionic.list | sudo tee /etc/apt/sources.list.d/tailscale.list \
    && apt update \
    && apt install -y tailscale

# --- 5. Entrypoint Script (Termasuk VNC dan noVNC) ---
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 🔥 Port Web noVNC 🔥
EXPOSE 6080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
