## Prerequisites
---
- EC2 instances deployed in gcp
- Allowed read/write bucket access from VM to GCP
- Firewall port opened
- Persistant volume for server created
- Bucket for mods and backups created:

### Creating bucket
---
gsutil mb -c standard -l europe-west3 gs://${gcp_bucket_name}
 
### Enable versioning
---
gsutil versioning set on  gs://minecraft-server-298410-backups

### List all versions
---
gsutil ls -a  gs://minecraft-server-298410-backups/

## Cusomom EC2 instance metadata 
---
- <key: startup-script, contents of *shutdown.sh*> (Alternatively add to bootstrap sctipt section of VM)
- <key: shutdown-script, value: contents of *shutdown.sh*>
