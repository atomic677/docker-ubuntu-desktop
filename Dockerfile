FROM --platform=linux/amd64 debian:12

ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm init systemd vim net-tools curl wget git tzdata openssl \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    firefox-esr adwaita-icon-theme

# Create user mehraz with password mehraz
RUN useradd -m -s /bin/bash mehraz && \
    echo "mehraz:mehraz" | chpasswd && \
    usermod -aG sudo mehraz

# Setup VNC directory for user mehraz
RUN mkdir -p /home/mehraz/.vnc && \
    touch /home/mehraz/.Xauthority && \
    chown -R mehraz:mehraz /home/mehraz

# Create startup script
RUN echo '#!/bin/bash\n\
mkdir -p /home/mehraz/.vnc\n\
echo "mehraz" | vncpasswd -f > /home/mehraz/.vnc/passwd\n\
chmod 600 /home/mehraz/.vnc/passwd\n\
chown -R mehraz:mehraz /home/mehraz/.vnc\n\
su - mehraz -c "vncserver -localhost no -geometry 1024x768 :1"\n\
openssl req -new -subj "/C=US" -x509 -days 365 -nodes -out /tmp/self.pem -keyout /tmp/self.pem\n\
websockify -D --web=/usr/share/novnc/ --cert=/tmp/self.pem 6080 localhost:5901\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

EXPOSE 5901
EXPOSE 6080

CMD ["/start.sh"]
