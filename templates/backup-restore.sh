#!/bin/bash

BACKUP_NAME=$1

SCREEN_NAME={{ screen_name }}
GCP_BUCKET_NAME={{ gcp_bucket_name }}
MINECRAFT_SERVER_HOME={{ minecraft_server_home }}
SYSTEMD_SERVICE_NAME={{ systemd_service_name }}

if [[ $1 == "latest" ]]; then
    BACKUP_NAME="world.zip"
    #$(gsutil ls -a gs://${GCP_BUCKET_NAME}/${BACKUP_NAME}/world.zip | tail -n 1)
fi

set -eE

catch() {
  echo "Backup restoring failed at line $LINENO. Timestamp $(date "+%Y%m%d-%H%M%S")" >> $MINECRAFT_SERVER_HOME/backup.log
}
trap catch ERR

# stop server
sudo service ${SYSTEMD_SERVICE_NAME} stop

# backup world
${MINECRAFT_SERVER_HOME}/backup.sh

# cp world to /tmp
if [[ -d world ]]; then
    sudo cp -rf ${MINECRAFT_SERVER_HOME}/world /tmp
fi

# remove all old worlds
sudo rm -rf ./world
sudo rm -rf ./world.zip

# cp backup to minecraft home
gsutil cp gs://${GCP_BUCKET_NAME}/${BACKUP_NAME} ${MINECRAFT_SERVER_HOME}/world.zip

# extract world
( cd  ${MINECRAFT_SERVER_HOME} && unzip -o world.zip )

sudo chown -R ${SYSTEMD_SERVICE_NAME}:${SYSTEMD_SERVICE_NAME} ./world

# start the server
sudo service ${SYSTEMD_SERVICE_NAME} start

echo "World was successfully restored. Timestamp $(date "+%Y%m%d-%H%M%S")" >> $MINECRAFT_SERVER_HOME/backup.log
