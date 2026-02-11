FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# ── Install desktop, VNC, noVNC and utilities ──────────────────────────
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
        xfce4 xfce4-goodies xubuntu-icon-theme \
        tigervnc-standalone-server tigervnc-common \
        novnc websockify \
        dbus-x11 x11-utils x11-xserver-utils x11-apps xauth \
        sudo xterm vim net-tools curl wget git tzdata \
        openssl ca-certificates software-properties-common

# ── Firefox via Mozilla Team PPA (snap does not work in containers) ────
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    printf 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
        > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:noble";' \
        > /etc/apt/apt.conf.d/51unattended-upgrades-firefox && \
    apt-get update -y && \
    apt-get install -y firefox

# ── VNC / X11 bootstrap files ─────────────────────────────────────────
RUN mkdir -p /root/.vnc && touch /root/.Xauthority

# xstartup – launches the XFCE4 session
RUN { \
      echo '#!/bin/sh'; \
      echo 'unset SESSION_MANAGER'; \
      echo 'unset DBUS_SESSION_BUS_ADDRESS'; \
      echo 'exec dbus-launch --exit-with-session startxfce4'; \
    } > /root/.vnc/xstartup && chmod +x /root/.vnc/xstartup

# Container entry-point script
# (Ubuntu 24.04 ships TigerVNC 1.13 which removed the legacy
#  "vncserver" Perl wrapper – we start Xtigervnc directly.)
RUN { \
      echo '#!/bin/bash'; \
      echo 'set -e'; \
      echo ''; \
      echo '# XDG runtime dir required by some desktop components'; \
      echo 'export XDG_RUNTIME_DIR=/tmp/runtime-root'; \
      echo 'mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"'; \
      echo ''; \
      echo '# X authority cookie'; \
      echo 'COOKIE=$(mcookie)'; \
      echo 'xauth add :1 MIT-MAGIC-COOKIE-1 "$COOKIE"'; \
      echo ''; \
      echo '# Start TigerVNC server'; \
      echo 'Xtigervnc :1 \'; \
      echo '    -geometry 1024x768 \'; \
      echo '    -SecurityTypes None \'; \
      echo '    -AlwaysShared \'; \
      echo '    -AcceptKeyEvents \'; \
      echo '    -AcceptPointerEvents \'; \
      echo '    -SendCutText \'; \
      echo '    -AcceptCutText \'; \
      echo '    -auth /root/.Xauthority \'; \
      echo '    -pn &'; \
      echo ''; \
      echo 'sleep 2'; \
      echo 'export DISPLAY=:1'; \
      echo ''; \
      echo '# Launch desktop session'; \
      echo '/root/.vnc/xstartup &'; \
      echo ''; \
      echo '# Self-signed TLS certificate for noVNC'; \
      echo 'openssl req -new -subj "/C=JP" -x509 -days 365 -nodes \'; \
      echo '    -out /tmp/self.pem -keyout /tmp/self.pem 2>/dev/null'; \
      echo ''; \
      echo '# Start noVNC websocket proxy'; \
      echo 'websockify -D --web=/usr/share/novnc/ --cert=/tmp/self.pem 6080 localhost:5901'; \
      echo ''; \
      echo '# Keep container alive'; \
      echo 'tail -f /dev/null'; \
    } > /startup.sh && chmod +x /startup.sh

# ── Cleanup ────────────────────────────────────────────────────────────
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 5901
EXPOSE 6080

CMD ["/startup.sh"]
