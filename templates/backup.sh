#!/bin/bash
SCREEN_NAME={{ screen_name }}
GCP_BUCKET_NAME={{ gcp_bucket_name }}
MINECRAFT_SERVER_HOME={{ minecraft_server_home }}

BACKUP_NAME="$(date "+%Y%m%d-%H%M%S")-world"

# turn off auto saves
screen -r ${SCREEN_NAME} -X stuff '/save-all\n/save-off\n'

# archive world
zip ${MINECRAFT_SERVER_HOME}/${BACKUP_NAME} ${MINECRAFT_SERVER_HOME}/world/*

# copy world to the bucket
gsutil cp ${MINECRAFT_SERVER_HOME}/${BACKUP_NAME}.zip gs://${GCP_BUCKET_NAME}/${BACKUP_NAME}.zip

# turn on auto saves
screen -r ${SCREEN_NAME} -X stuff '/save-on\n'
