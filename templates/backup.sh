#!/bin/bash
SCREEN_NAME={{ screen_name }}
GCP_BUCKET_NAME={{ gcp_bucket_name }}
MINECRAFT_SERVER_HOME={{ minecraft_server_home }}
SYSTEMD_SERVICE_NAME={{ systemd_service_name }}
BACKUP_NAME="world"

echo "Begin."

SCREEN_ACTIVE=$(sudo systemctl is-active minecraft | grep active)

set -eE

catch() {
  echo "ERROR at line $LINENO."
  echo "Backup failed at line $LINENO. Timestamp $(date "+%Y%m%d-%H%M%S")" >> $MINECRAFT_SERVER_HOME/backup.log
}
trap catch ERR

if [[ $SCREEN_ACTIVE ]]; then
    # turn off auto saves
    echo "Server is active. Saving all and turning off auto-saves..."
    sudo -u ${SYSTEMD_SERVICE_NAME} screen -r ${SCREEN_NAME} -X stuff '/save-all\n/save-off\n'
fi

# archive world
echo "Archiving current world..."
( cd ${MINECRAFT_SERVER_HOME} && zip -o ${BACKUP_NAME} world/*)

# copy world to the bucket
echo "Pushing backup to gcp bucket..."
gsutil cp ${MINECRAFT_SERVER_HOME}/${BACKUP_NAME}.zip gs://${GCP_BUCKET_NAME}/world.zip

echo "Removing created archive..."
rm -rf ${MINECRAFT_SERVER_HOME}/world.zip

if [[ $SCREEN_ACTIVE ]]; then
    # turn on auto saves
    echo "Server is active. Turning on auto-saves..."
    sudo -u ${SYSTEMD_SERVICE_NAME} screen -r ${SCREEN_NAME} -X stuff '/save-on\n'
fi

echo "World was successfully saved. Timestamp $(date "+%Y%m%d-%H%M%S")" >> $MINECRAFT_SERVER_HOME/backup.log

echo "End."
