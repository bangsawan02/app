#!/bin/bash
# file: entrypoint.sh (Revisi Akhir)

# Dijalankan sebagai ROOT (sesuai setting akhir Dockerfile)

VNC_USER="developer"
VNC_DISPLAY=":1"
VNC_PORT="5901"
NOVNC_PORT="6080"
# Variabel lingkungan TAILSCALE_AUTH_KEY dimuat dari GitHub Secrets

# 1. Instalasi Tailscale (Menggunakan script resmi dari log berhasil Anda)
echo "--- Memasang Tailscale di Container ---"
curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1

# 2. Mulai D-Bus Daemon 
# Diperlukan untuk Xfce dan aplikasi desktop
echo "--- Memulai D-Bus Daemon ---"
eval $(dbus-launch --sh-syntax)

# 3. Mulai Tailscale Daemon dan Otentikasi
echo "--- Memulai Tailscale Daemon dan Autentikasi ---"
# tailscaled dijalankan sebagai root (karena ENTRYPOINT user=root)
tailscaled & 
sleep 5 # Berikan jeda pendek agar daemon dapat memulai

# Otorisasi Tailscale
tailscale up --authkey=$TAILSCALE_AUTH_KEY --hostname=github-runner-vnc --accept-routes

# 4. Tunggu koneksi & Dapatkan IP
echo "--- Menunggu Tailscale Connect ---"
sleep 10
IP_VNC=$(tailscale ip -4)
echo "Tailscale IP: $IP_VNC"

# 5. Mulai VNC Server dan noVNC (Dialihkan ke User Developer)
echo "--- Memulai VNC Server dan noVNC sebagai $VNC_USER ---"

# Jalankan Xfce/VNC dan noVNC sebagai user non-root 'developer'
su - $VNC_USER -c "
    /usr/bin/vncserver $VNC_DISPLAY -geometry 1280x800 -depth 24; 
    /opt/noVNC/utils/websockify/run --web /opt/noVNC $NOVNC_PORT localhost:$VNC_PORT &
"

# 6. Output dan Pertahankan Container Tetap Berjalan
echo "::notice file=README.md,line=1::Akses Desktop (dari Tailnet Anda) di URL:"
echo "::notice file=README.md,line=1::http://$IP_VNC:$NOVNC_PORT/vnc.html"
echo "::set-output name=tailscale_ip::$IP_VNC"

# Pertahankan container tetap berjalan agar sesi VNC dapat diakses.
exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
