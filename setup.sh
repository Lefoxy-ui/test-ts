#!/bin/bash
set -e

# Farben
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

echo -e "${GREEN}=== TeamSpeak 3 Server Installer für Debian ===${NC}"

# Root-Check
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Bitte als root ausführen!${NC}"
   exit 1
fi

# Pakete installieren
apt update && apt upgrade -y
apt install wget tar bzip2 curl -y

# Benutzer anlegen
if ! id "teamspeak" &>/dev/null; then
    adduser --disabled-login --gecos "" teamspeak
fi

cd /home/teamspeak

# Neueste Version von der offiziellen API holen
LATEST=$(curl -s https://teamspeak.com/versions/server.json | grep -oP '(?<="linux": {"amd64": {"version": ")[^"]+')
URL=$(curl -s https://teamspeak.com/versions/server.json | grep -oP "(?<=\"version\": \"$LATEST\", \"full\": \")[^\"]+" | grep linux_amd64)

echo -e "${GREEN}Lade TeamSpeak $LATEST herunter...${NC}"
sudo -u teamspeak wget "$URL" -O ts3server.tar.bz2

# Entpacken
sudo -u teamspeak tar -xvjf ts3server.tar.bz2
sudo -u teamspeak mv teamspeak3-server_linux_amd64/* .
sudo -u teamspeak rm -rf teamspeak3-server_linux_amd64 ts3server.tar.bz2

# Lizenz akzeptieren
sudo -u teamspeak touch .ts3server_license_accepted

# systemd Service
cat <<EOF >/etc/systemd/system/teamspeak.service
[Unit]
Description=TeamSpeak 3 Server
After=network.target

[Service]
WorkingDirectory=/home/teamspeak
User=teamspeak
ExecStart=/home/teamspeak/ts3server_startscript.sh start
ExecStop=/home/teamspeak/ts3server_startscript.sh stop
PIDFile=/home/teamspeak/ts3server.pid
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now teamspeak

echo -e "${GREEN}Installation abgeschlossen!${NC}"
echo -e "${GREEN}Logs ansehen mit:${NC} journalctl -u teamspeak -f"
