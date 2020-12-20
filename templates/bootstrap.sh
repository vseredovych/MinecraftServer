#!/bin/bash
mount /dev/disk/by-id/google-minecraft-disk /home/minecraft
(crontab -l | grep -v -F "/home/minecraft/backup.sh" ; echo "0 */4 * * * /home/minecraft/backup.sh")| crontab -
cd /home/minecraft
sudo service minecraft start