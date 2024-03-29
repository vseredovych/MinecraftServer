#!/bin/bash
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Define some variables manually
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
GCP_PERSISTANT_VOLUME_NAME="google-google-minecraft-disk"
SYSTEMD_SERVICE_NAME="minecraft"
MINECRAFT_SERVER_HOME="/home/minecraft"

# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Mount volume, add crontab for backups and start minecraft
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
mount /dev/disk/by-id/${GCP_PERSISTANT_VOLUME_NAME} ${MINECRAFT_SERVER_HOME}
sudo service ${SYSTEMD_SERVICE_NAME} start
