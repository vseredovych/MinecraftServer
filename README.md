# MinecraftServer_Configs

startup-script	
#!/bin/bash
mount /dev/disk/by-id/google-minecraft-disk /home/minecraft
(crontab -l | grep -v -F "/home/minecraft/backup.sh" ; echo "0 */4 * * * /home/minecraft/backup.sh")| crontab -
cd /home/minecraft
screen -d -m -S mcs java -Xms2G -Xmx5G -d64 -jar forge-1.12.2-14.23.5.2838-universal.jar nogui

#!/bin/bash
/home/minecraft/backup.sh
sudo screen -r mcs -X stuff '/stop\n'
