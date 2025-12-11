#!/bin/bash
# file: entrypoint.sh

# ==========================================================
# Skrip Startup VNC, Tailscale, dan noVNC
# ==========================================================

# User yang menjalankan VNC dan noVNC
VNC_USER="developer"
VNC_DISPLAY=":1"
VNC_PORT="5901"
NOVNC_PORT="6080"

# 1. Mulai D-Bus Daemon (untuk Xfce)
echo "--- Memulai D-Bus Daemon ---"
eval $(dbus-launch --sh-syntax)

# 2. Mulai Tailscale Daemon dan Autentikasi
echo "--- Mengautentikasi Tailscale ---"
tailscaled &
sleep 5
# Gunakan --accept-dns dan --accept-routes jika diperlukan di lingkungan Anda
sudo tailscale up --authkey=$TAILSCALE_AUTH_KEY --hostname=github-runner-vnc --accept-routes

echo "--- Menunggu Tailscale Connect ---"
sleep 15
IP_VNC=$(tailscale ip -4)

# 3. Mulai VNC Server (Berjalan sebagai user 'developer')
echo "--- Memulai VNC Server di $VNC_DISPLAY ---"
su - $VNC_USER -c "/usr/bin/vncserver $VNC_DISPLAY -geometry 1280x800 -depth 24"

# 4. Mulai noVNC (Websockify)
# Ini meneruskan koneksi dari port 6080 (Web) ke VNC Port (5901)
echo "--- Memulai noVNC di Port $NOVNC_PORT ---"
/opt/noVNC/utils/websockify/run --web /opt/noVNC $NOVNC_PORT localhost:$VNC_PORT &

# 5. Output dan Pertahankan Container Tetap Berjalan
echo "::notice file=README.md,line=1::Akses Desktop di URL berikut (dari Tailnet Anda):"
echo "::notice file=README.md,line=1::http://$IP_VNC:$NOVNC_PORT/vnc.html"
echo "::set-output name=tailscale_ip::$IP_VNC"

exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
