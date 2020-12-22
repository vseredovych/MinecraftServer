#!/bin/bash
SCREEN_NAME={{ screen_name }}
GCP_BUCKET_NAME={{ gcp_bucket_name }}
MINECRAFT_SERVER_HOME={{ minecraft_server_home }}

BACKUP_NAME="world"

SCREEN_ACTIVE=$(screen -list | grep ${SCREEN_NAME})

set -eE

catch() {
  echo "Backup failed at line $LINENO. Timestamp $(date "+%Y%m%d-%H%M%S")" >> $MINECRAFT_SERVER_HOME/backup.log
}
trap catch ERR

if [[ $SCREEN_ACTIVE ]]; then
    # turn off auto saves
    screen -r ${SCREEN_NAME} -X stuff '/save-all\n/save-off\n'
fi

# archive world
zip ${MINECRAFT_SERVER_HOME}/${BACKUP_NAME} ${MINECRAFT_SERVER_HOME}/world/*

# copy world to the bucket
gsutil cp ${MINECRAFT_SERVER_HOME}/${BACKUP_NAME}.zip gs://${GCP_BUCKET_NAME}/${BACKUP_NAME}.zip

if [[ $SCREEN_ACTIVE ]]; then
    # turn on auto saves
    screen -r ${SCREEN_NAME} -X stuff '/save-on\n'
fi

echo "World was successfully saved. Timestamp $(date "+%Y%m%d-%H%M%S")" >> $MINECRAFT_SERVER_HOME/backup.log
