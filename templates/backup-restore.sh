#!/bin/bash

BACKUP_NAME=$1

SCREEN_NAME={{ screen_name }}
GCP_BUCKET_NAME={{ gcp_bucket_name }}
MINECRAFT_SERVER_HOME={{ minecraft_server_home }}
SYSTEMD_SERVICE_NAME={{ systemd_service_name }}

echo "Begin."

if [[ $1 == "latest" ]]; then
    # Split line by slash and get the world name
    echo "Setting the latest backup name..."
    BACKUP_NAME=$(gsutil ls -a gs://${GCP_BUCKET_NAME}/world.zip | tail -n 1 | awk '{split($0,a,"/"); print a[4]}')
    echo ${BACKUP_NAME}
fi

set -eE

catch() {
  echo "ERROR at line $LINENO."
  echo "Backup restoring failed at line $LINENO. Timestamp $(date "+%Y/%m/%d-%H:%M:%S")" >> $MINECRAFT_SERVER_HOME/backup.log
}
trap catch ERR

# stop server
echo "Stoping server..."
sudo service ${SYSTEMD_SERVICE_NAME} stop

if [[ -d world ]]; then
    # backup world
    echo "World exists runing backup script..."
    ${MINECRAFT_SERVER_HOME}/backup.sh
    
    # cp world to /tmp
    sudo cp -rf ${MINECRAFT_SERVER_HOME}/world /tmp
fi

# remove all old worlds
sudo rm -rf ${MINECRAFT_SERVER_HOME}/world
sudo rm -rf ${MINECRAFT_SERVER_HOME}/world.zip

# cp backup to minecraft home
echo "Fetching world..."
/snap/bin/gsutil cp gs://${GCP_BUCKET_NAME}/${BACKUP_NAME} ${MINECRAFT_SERVER_HOME}/world.zip

# extract world
echo "Restoring backup..."
( cd  ${MINECRAFT_SERVER_HOME} && unzip -o world.zip )

echo "Setting correct permissions on the world folder..."
sudo chown -R ${SYSTEMD_SERVICE_NAME}:${SYSTEMD_SERVICE_NAME} ./world

# start the server
echo "Starting server..."
sudo service ${SYSTEMD_SERVICE_NAME} start

echo "World was successfully restored. Timestamp $(date "+%Y/%m/%d-%H:%M:%S")" >> $MINECRAFT_SERVER_HOME/backup.log

echo "End."
