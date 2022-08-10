# Minecraft Server
---

This project is aimed to automate and simplify launching of custom Minecraft server on GCP.
It includes logic for:
- [auto-deployment](server-configs/autoconfig.sh) of all requirement configurations for either vanilla or forge (with mods) minecraft server. 
- storing saves on google persistent storage
- auto backups to the GCP bucket per specified interval of time and before shutting down the server
- [start-up](server-configs/bootstrap.sh) and shut-down [scripts](server-configs/shutdown.sh) for 
- script for manual [back-up](server-configs/templates/backup.sh) and [restoration](server-configs/templates/backup-restore.sh) of save
- Telegram integration for notifying in case of backup failures (if any)
- [Telegram bot](telegram-bot) based on Google Cloud Functions for stopping/starting server from a specific telegram group.

## Prerequisites
---
- Custom GCP Compute Engine instance created
- Google Bucket for mods and backups created
- Compute Engine instance has read/write access to the bucket
- The port 25565 is opened on firewall (or any other port configured for a Minecraft server)
- Persistent volume for Compute Engine instance is created

### Creating bucket
Create bucket in the chosen region
```
gsutil mb -c standard -l europe-west3 gs://${gcp_bucket_name}
```

### Enable versioning
```
gsutil versioning set on gs://minecraft-server-298410-backups
```

### List all versions
```
gsutil ls -a  gs://minecraft-server-298410-backups/
```

### Custom Compute Engine instance metadata
Set custom metadata for the instance, as follows
- <key: startup-script, contents of *[bootstrap.sh](server-configs/bootstrap.sh)*> (Alternatively add to bootstrap sctipt section of VM)
- <key: shutdown-script, value: contents of *[shutdown.sh](server-configs/shutdown.sh)*>

### Install Minecraft Server On Compute Engine instance
Make sure to customize variables in ALL files in [server-configs](server-configs) up to your needs.

Use the following commands to install Minecraft Server:
- ```git clone https://github.com/vseredovych/MinecraftServer.git```
- ```sudo ./MinecraftServer/server-configs/autoconfig.sh install```

In case something went wrong, you can debug and clean everything by clean option.: 
- ```sudo ./MinecraftServer/server-configs/autoconfig.sh clean```

Once the script is fixed, try installing server once again:
- ```sudo ./MinecraftServer/server-configs/autoconfig.sh install```

# Telegram bot
---
The creation of the bot account was influenced by the following tutorial:
- https://github.com/FedericoTartarini/telegram-bot-cloud-function-youtube

## Prerequisites
---
- Create telegram bot via BotFather and get bot ```TELEGRAM_TOKEN```
- Create telegram group and add the bot to this group. Get the ```CHAT_ID``` of the group.
- Get ```INSTANCE_ID```, ```ZONE_ID``` and ```PROJECT_ID``` of the Cloud Compute instance.

### Create a Google Cloud Function 

Run the following command (by replacing the corresponding variables) to deploy the Google Cloud Function which will be hosting the telegram bot logic.
```
gcloud functions deploy telegram_bot --set-env-vars "TELEGRAM_TOKEN=<TELEGRAM_TOKEN>" --set-env-vars "CHAT_ID=<CHAT_ID>" --set-env-vars "INSTANCE_ID=<INSTANCE_ID>" --set-env-vars "ZONE_ID=<ZONE_ID>" --set-env-vars "PROJECT_ID=<PROJECT_ID>" --set-env-vars "TELEGRAM_BOT_NAME=<TELEGRAM_BOT_NAME>" --runtime python38 --trigger-http
```
* Here webhook is the name of the function in the `main.py` file
* Bot Telegram token and other variables need to be specified with the `--set-env-vars` option
* `--runtime python38` describe the environment used by our function, Python 3.8 in this case
* `--trigger-http` is the type of trigger associated to this function

Set up the telegram webhook by the following command, where URL is given from the output of the previous command:
```
curl "https://api.telegram.org/bot<TELEGRAM_TOKEN>/setWebhook?url=<URL>"
```
  


### TODOs
- simplify the process of choosing vanilla or forge
- add markdown or HTML for telegram bot messages