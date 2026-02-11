FROM --platform=linux/amd64 debian:12

ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm init systemd vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    firefox-esr adwaita-icon-theme

# Create user mehraz with password mehraz
RUN useradd -m -s /bin/bash mehraz && \
    echo "mehraz:mehraz" | chpasswd && \
    usermod -aG sudo mehraz

# Setup VNC for user mehraz
USER mehraz
WORKDIR /home/mehraz
RUN mkdir -p /home/mehraz/.vnc && \
    echo "mehraz" | vncpasswd -f > /home/mehraz/.vnc/passwd && \
    chmod 600 /home/mehraz/.vnc/passwd
RUN touch /home/mehraz/.Xauthority

USER root
EXPOSE 5901
EXPOSE 6080

CMD bash -c "su - mehraz -c 'vncserver -localhost no -geometry 1024x768 :1' && openssl req -new -subj '/C=US' -x509 -days 365 -nodes -out /tmp/self.pem -keyout /tmp/self.pem && websockify -D --web=/usr/share/novnc/ --cert=/tmp/self.pem 6080 localhost:5901 && tail -f /dev/null"
