#!/bin/bash
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Define some variables manually
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
BACKUP_SCRIPT="/home/minecraft/backup.sh"
SYSTEMD_SERVICE_NAME="minecraft"

# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Backup server and stop
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
./BACKUP_SCRIPT
sudo service ${SYSTEMD_SERVICE_NAME} stop
