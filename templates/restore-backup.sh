#!/bin/bash

BACKUP_NAME=$1

SCREEN_NAME={{ screen_name }}
GCP_BUCKET_NAME={{ gcp_bucket_name }}
MINECRAFT_SERVER_HOME={{ minecraft_server_home }}
SYSTEMD_SERVICE_NAME={{ systemd_service_name }}


SCREEN_ACTIVE=$(screen -list | grep ${SCREEN_NAME})

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
cp -rf ${MINECRAFT_SERVER_HOME}/world /tmp


# cp backup to minecraft home
gsutil cp gs://${GCP_BUCKET_NAME}/${BACKUP_NAME} ${MINECRAFT_SERVER_HOME}/world.zip

# extract world
unzip ${MINECRAFT_SERVER_HOME}/world.zip


# start the server
sudo service ${SYSTEMD_SERVICE_NAME} start

echo "World was successfully restored. Timestamp $(date "+%Y%m%d-%H%M%S")" >> $MINECRAFT_SERVER_HOME/backup.log
