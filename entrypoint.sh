#!/bin/bash
# file: entrypoint.sh

# ==========================================================
# Skrip Startup VNC, Tailscale, dan noVNC
# ==========================================================

VNC_USER="developer"
VNC_DISPLAY=":1"
VNC_PORT="5901"
NOVNC_PORT="6080"
TAILSCALE_SOCK="/var/run/tailscale/tailscaled.sock"

# 1. Mulai D-Bus Daemon (untuk Xfce)
echo "--- Memulai D-Bus Daemon ---"
eval $(dbus-launch --sh-syntax)

# 2. Mulai Tailscale Daemon
echo "--- Memulai Tailscale Daemon (sebagai root) ---"
# Pastikan daemon berjalan di background dan sebagai root
sudo tailscaled &

# 3. WAITING LOOP: Tunggu Socket Daemon
echo "--- Menunggu Tailscale Socket ($TAILSCALE_SOCK) aktif ---"
TIMEOUT=30
while [ ! -e $TAILSCALE_SOCK ] && [ $TIMEOUT -gt 0 ]; do
    echo "Socket belum ditemukan. Menunggu $TIMEOUT detik lagi..."
    sleep 2
    TIMEOUT=$((TIMEOUT-2))
done

if [ $TIMEOUT -le 0 ]; then
    echo "ERROR: Tailscale daemon gagal memulai dalam waktu yang ditentukan."
    exit 1
fi

# 4. Otorisasi Tailscale
echo "--- Mengautentikasi Tailscale ---"
# Gunakan sudo untuk menjalankan klien tailscale
sudo tailscale up --authkey=$TAILSCALE_AUTH_KEY --hostname=github-runner-vnc --accept-routes

# 5. Tunggu hingga Tailscale terhubung dan mendapatkan IP
echo "--- Menunggu Tailscale Connect ---"
sleep 15
IP_VNC=$(sudo tailscale ip -4)

# 6. Mulai VNC Server (Berjalan sebagai user 'developer')
echo "--- Memulai VNC Server di $VNC_DISPLAY ---"
/usr/bin/vncserver $VNC_DISPLAY -geometry 1280x800 -depth 24

# 7. Mulai noVNC (Websockify)
echo "--- Memulai noVNC di Port $NOVNC_PORT ---"
/opt/noVNC/utils/websockify/run --web /opt/noVNC $NOVNC_PORT localhost:$VNC_PORT &

# 8. Output dan Pertahankan Container Tetap Berjalan
echo "::notice file=README.md,line=1::Akses Desktop di URL berikut (dari Tailnet Anda):"
echo "::notice file=README.md,line=1::http://$IP_VNC:$NOVNC_PORT/vnc.html"
echo "::set-output name=tailscale_ip::$IP_VNC"

exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
