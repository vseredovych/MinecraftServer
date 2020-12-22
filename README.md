## Prerequisites
---
- EC2 instances deployed in gcp
- Firewall port opened
- Persistant volume for server created
- Bucket for mods and backups created:

### Creating bucket
gsutil mb -c standard -l europe-west3 gs://${gcp_bucket_name}
 
### Enable versioning
gsutil versioning set on  gs://minecraft-server-298410-backups

### List all versions
gsutil ls -a  gs://minecraft-server-298410-backups/

## Cusomom EC2 instance metadata
startup-script - bootstrap.sh
shutdown-script - shutdown.sh
