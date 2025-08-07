#!/bin/bash
set -e

GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

echo -e "${GREEN}=== TeamSpeak 3 Server Installer für Debian ===${NC}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Bitte als root ausführen!${NC}"
   exit 1
fi

apt update && apt upgrade -y
apt install wget tar bzip2 curl -y

if ! id "teamspeak" &>/dev/null; then
    adduser --disabled-login --gecos "" teamspeak
fi

cd /home/teamspeak

LATEST=$(curl -s https://teamspeak.com/versions/server.json | grep -oP '(?<="linux": {"amd64": {"version": ")[^"]+')
URL=$(curl -s https://teamspeak.com/versions/server.json | grep -oP "(?<=\"version\": \"$LATEST\", \"full\": \")[^\"]+" | grep linux_amd64)

echo -e "${GREEN}Lade TeamSpeak $LATEST herunter...${NC}"
sudo -u teamspeak wget "$URL" -O ts3server.tar.bz2

sudo -u teamspeak tar -xvjf ts3server.tar.bz2
sudo -u teamspeak mv teamspeak3-server_linux_amd64/* .
sudo -u teamspeak rm -rf teamspeak3-server_linux_amd64 ts3server.tar.bz2

sudo -u teamspeak touch .ts3server_license_accepted

echo -e "${GREEN}Starte TeamSpeak zum Ermitteln des Admin-Tokens...${NC}"
TOKEN=$(sudo -u teamspeak ./ts3server_startscript.sh start inifile=ts3server.ini | tee /tmp/ts3_firststart.log | grep "token=" | awk -F= '{print $2}')
sudo -u teamspeak ./ts3server_startscript.sh stop

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
echo -e "${GREEN}Server Admin Token:${NC} $TOKEN"
