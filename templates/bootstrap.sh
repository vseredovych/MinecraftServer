#!/bin/bash
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Define some variables manually
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
MINECRAFT_SERVER_HOME="/home/minecraft/backup.sh"
GCP_PERSISTANT_VOLUME_NAME="google-minecraft-disk"
SYSTEMD_SERVICE_NAME="minecraft"

# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Mount volume, add crontab for backups and start minecraft
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
mount /dev/disk/by-id/${GCP_PERSISTANT_VOLUME_NAME} ${MINECRAFT_SERVER_HOME}

crontab -l | grep -v -F "${MINECRAFT_SERVER_HOME}/backup.sh" ; echo "*/30 * * * * ${MINECRAFT_SERVER_HOME}/backup.sh") | crontab -

sudo service ${SYSTEMD_SERVICE_NAME} start
