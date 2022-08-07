#!/bin/bash
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Define some variables manually
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# minecraft variables
minecraft_server_version="1.19.2"

# Get the forge installer download link here - http://files.minecraftforge.net/maven/net/minecraftforge/forge/index_1.12.2.html 
forge_installer_download_url="https://maven.minecraftforge.net/net/minecraftforge/forge/1.19-41.1.0/forge-1.19-41.1.0-installer.jar"
# Get the vanilla server download link here - https://www.minecraft.net/ru-ru/article/minecraft-1122-released
vanilla_server_download_url="https://launcher.mojang.com/mc/game/1.12.2/server/886945bfb2b978778c3a0288fd7fab09d315b25f/server.jar"

# gcp variables manually
gcp_persistant_volume_name="google-minecraft-disk"
gcp_bucket_name="minecraft-server-20220807-backups"
# NO MODS # gcp_bucket_mods_archive_path="mods.zip"

# system variables
minecraft_server_user="minecraft"
systemd_service_name="minecraft"
ram_min=1
ram_max=4
screen_name="mcs"

telegram_token=""
telegram_chat_id=""

# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Script Options
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––

if [[ $1 == "help" ]]; then
    echo "Use clean option to clean all change made by script"
    echo "Use install option to install minecraft server"
fi

if [[ $1 == "clean" ]]; then
    #gsutil rb -f gs://${gcp_bucket_name}
    umount /home/${minecraft_server_user}
    rm -rf /home/${minecraft_server_user}
    userdel ${minecraft_server_user}
    exit 0
fi

if [[ $1 != "install" ]]; then
    exit 0
fi

# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Prerequisites
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––

# Create minecraft user 
if ! [[ $(id -u ${minecraft_server_user}) ]]; then
    sudo adduser ${minecraft_server_user} --gecos "FirstName LastName,RoomNumber,WorkPhone,HomePhone" --disabled-password
else
    echo "WARNING: User with name \"${minecraft_server_user}\" already exists"
fi

# Format disk to ext4 format
sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/${gcp_persistant_volume_name}

# Mount persistant volume for the first time
sudo mount -o discard,defaults /dev/disk/by-id/${gcp_persistant_volume_name} /home/${minecraft_server_user}

# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Install dependencies
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
sudo apt-get install zip unzip wget screen -y

# Install jdk-8 and set alternatives
sudo apt-get install openjdk-8-jdk -y
sudo update-java-alternatives -s java-1.8.0-openjdk-amd64 --jre-headless

# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Install minecraft server
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
( cd /home/${minecraft_server_user} && wget -O "forge-installer-${minecraft_server_version}.jar" ${forge_installer_download_url} )
( cd /home/${minecraft_server_user} && wget ${vanilla_server_download_url} )

( cd /home/${minecraft_server_user} && /usr/bin/java -jar "forge-installer-${minecraft_server_version}.jar" --installServer )
( cd /home/${minecraft_server_user} && rm -rf "forge-installer-${minecraft_server_version}.jar" )

( cd /home/${minecraft_server_user} && echo 'eula=true' > eula.txt )

sudo cp -rf ./server.properties /home/${minecraft_server_user}/server.properties

FORGE_SERVER_RUN_FILE=$(ls /home/${minecraft_server_user} | grep "forge-1.12.2.*.jar")

# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Install minecraft server mods
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
#
#NO MODS
#if [[ ${gcp_bucket_mods_archive_path} ]]; then
#    ( cd /home/${minecraft_server_user} && gsutil cp gs://${gcp_bucket_name}/$gcp_bucket_mods_archive_path /home/${minecraft_server_user}/mods.zip )
#    ( cd /home/${minecraft_server_user} && unzip /home/${minecraft_server_user}/mods.zip )
#    ( cd /home/${minecraft_server_user} && rm -rf mods.zip )
#else
#    echo "WARNING: mods variable hasn't been configured. No mods will be installed."
#fi
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Create systemd service
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
sudo cp -rf ./templates/minecraft-server.service /etc/systemd/system/${systemd_service_name}.service

sed -i "s/{{ user }}/${minecraft_server_user}/" /etc/systemd/system/${systemd_service_name}.service
sed -i "s/{{ group }}/${minecraft_server_user}/" /etc/systemd/system/${systemd_service_name}.service
sed -i "s/{{ minecraft_server_home }}/\/home\/${minecraft_server_user}/" /etc/systemd/system/${systemd_service_name}.service

sed -i "s/{{ ram_min }}/${ram_min}/" /etc/systemd/system/${systemd_service_name}.service
sed -i "s/{{ ram_max }}/${ram_max}/" /etc/systemd/system/${systemd_service_name}.service
sed -i "s/{{ screen_name }}/${screen_name}/" /etc/systemd/system/${systemd_service_name}.service
sed -i "s/{{ forge_server_run_fule }}/${FORGE_SERVER_RUN_FILE}/" /etc/systemd/system/${systemd_service_name}.service

sudo systemctl daemon-reload

# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Configure backup script
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
sudo cp -rf ./templates/backup.sh /home/${minecraft_server_user}/backup.sh

sed -i "s/{{ screen_name }}/${screen_name}/" /home/${minecraft_server_user}/backup.sh
sed -i "s/{{ gcp_bucket_name }}/${gcp_bucket_name}/" /home/${minecraft_server_user}/backup.sh
sed -i "s/{{ minecraft_server_home }}/\/home\/${minecraft_server_user}/" /home/${minecraft_server_user}/backup.sh
sed -i "s/{{ systemd_service_name }}/${systemd_service_name}/" /home/${minecraft_server_user}/backup.sh

sed -i "s/{{ telegram_token }}/${telegram_token}/" /home/${minecraft_server_user}/backup.sh
sed -i "s/{{ telegram_chat_id }}/${telegram_chat_id}/" /home/${minecraft_server_user}/backup.sh

# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Configure backup restore script
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
sudo cp -rf ./templates/backup-restore.sh /home/${minecraft_server_user}/backup-restore.sh

sed -i "s/{{ screen_name }}/${screen_name}/" /home/${minecraft_server_user}/backup-restore.sh
sed -i "s/{{ gcp_bucket_name }}/${gcp_bucket_name}/" /home/${minecraft_server_user}/backup-restore.sh
sed -i "s/{{ minecraft_server_home }}/\/home\/${minecraft_server_user}/" /home/${minecraft_server_user}/backup-restore.sh
sed -i "s/{{ systemd_service_name }}/${systemd_service_name}/" /home/${minecraft_server_user}/backup-restore.sh

# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Start minecraft server
# -------–––––––––––––––––––––––––––––––––––––––––––––––––––––––
sudo chown -R ${minecraft_server_user}:${minecraft_server_user} /home/${minecraft_server_user}
sudo chmod +x /home/${minecraft_server_user}/backup.sh
sudo chmod +x /home/${minecraft_server_user}/backup-restore.sh

(sudo crontab -l | grep -v -F "/home/${minecraft_server_user}/backup.sh" ; echo "*/20 * * * * sudo /home/${minecraft_server_user}/backup.sh > /var/log/cron.log 2>&1") | sudo crontab -

sudo systemctl start ${systemd_service_name}
sudo systemctl enable ${systemd_service_name}
