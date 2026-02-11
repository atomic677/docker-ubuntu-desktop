FROM --platform=linux/amd64 debian:12

ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server tigervnc-common novnc websockify \
    sudo xterm init systemd vim net-tools curl wget git tzdata openssl \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    firefox-esr adwaita-icon-theme

# Create user mehraz with password mehraz
RUN useradd -m -s /bin/bash mehraz && \
    echo "mehraz:mehraz" | chpasswd && \
    usermod -aG sudo mehraz

# Setup VNC for user mehraz - create password file manually
RUN mkdir -p /home/mehraz/.vnc && \
    printf 'mehraz\nmehraz\nn\n' | tigervncpasswd /home/mehraz/.vnc/passwd && \
    chmod 600 /home/mehraz/.vnc/passwd && \
    touch /home/mehraz/.Xauthority && \
    chown -R mehraz:mehraz /home/mehraz

EXPOSE 5901
EXPOSE 6080

CMD bash -c "su - mehraz -c 'tigervncserver -localhost no -geometry 1024x768 :1' && openssl req -new -subj '/C=US' -x509 -days 365 -nodes -out /tmp/self.pem -keyout /tmp/self.pem && websockify -D --web=/usr/share/novnc/ --cert=/tmp/self.pem 6080 localhost:5901 && tail -f /dev/null"
