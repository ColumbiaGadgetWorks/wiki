## Installation

A file named `.env` is required to set the database credentials. `dev.env` can be copied into `.env` to create one.

### Production
#### MariaDB  
  
A TrueNAS dataset was created with default settings named `mariadb`.

The mariaDB app was installed through the TrueNAS app store using the following settings.

```
Application Name: mariadb
Version: default

Image Version: v11
User: wiki_schema
Password: password for wiki_schema
Database: wiki
Root Password: password for root
Auto Upgrade: off
Additional Environment Variables: empty

Port Bind Mode: Publish port on the host for external access
Port Number: default
Host IPs: empty
Networks: empty

Data Storage Type: Host Path
Host Path: Path to the dataset created earlier
Additional Storage: empty

Labels Configuration: empty

CPUs: default
Memory: 2048
```

The mariaDB user/group then needs to be given ownership of this dataset via `chown -R 999:999 /mnt/data/mariadb` from the shell.

#### Custom App Container Configuration for the Wiki  

A custom app was created for the wiki using the UI with the following settings:

```
Application Name: wiki

Repository: ghcr.io/columbiagadgetworks/wiki
Tag: latest
Pull Policy: Pull the image if it is not already present on the host.

Timezone: 'America/Chicago' timezone

Environment Variables: See the shared secrets vault for these values
DATABASE_HOST:
DATABASE_NAME:
MYSQL_ROOT_PASSWORD:
WIKI_ADMIN_USER:
WIKI_ADMIN_PASSWORD:
WIKI_DB_APP_USER:
WIKI_DB_APP_PASSWORD:
WIKI_DB_SCHEMA_USER:
WIKI_DB_SCHEMA_PASSWORD:
WIKI_URL:

Restart Policy: Unless Stopped - Restarts the container irrespective of the exit code but stops restarting when the service is stopped or removed.

TTY: Checked

Ports:
  Port Bind Mode: Publish port on the host for external access
  Host Port: 8090
  Container Port: 80
  Protocol: TCP

Storage Configuration:
  This is the path inside the docker container where the images are stored. Found in docker-compose.yml
  Mount Path: /var/www/html/images
  Dataset Name: wiki-images

```
This will create a zfs dataset which will not appear in the UI. The location generated at the time of this writing is `/mnt/.ix-apps/app_mounts/wiki/wiki-images`.  
This dataset will need its permissions changed to allow the wiki application user access which should be `www-data` which has a user id of `33`.  
So to set the correct permissions, this command is run in the TrueNAS console.  

```shell
sudo chown -R 33:33 /mnt/.ix-apps/app_mounts/wiki/wiki-images && sudo chmod -R 775 /mnt/.ix-apps/app_mounts/wiki/wiki-images
```

#### Logging  
To limit the logs, a generic dataset was created called `log_storage_limit_init_script`  

Then the following script was created in the dataset via the shell.  
```shell
{
sudo tee /mnt/data/log_storage_limit_init_script/daemon-log-config.sh > /dev/null << 'EOF'
#!/bin/bash
systemctl stop docker
jq '. + {"log-opts": {"max-size": "10m", "max-file": "3"}}' /etc/docker/daemon.json > /tmp/daemon.json
mv /tmp/daemon.json /etc/docker/daemon.json
systemctl start docker
EOF
} && sudo chmod +x /mnt/data/log_storage_limit_init_script/daemon-log-config.sh
```

To run the script, the configuration is found in TrueNAS's advanced settings under the Init/Shutdown Script section  
  
The form's fields/values are:  
```
Description: Confirgure Logging Storage Limits
Type: Script
Script: /mnt/data/log_storage_limit_init_script/daemon-log-config.sh
When: Post Init
Enabled: Checked
Timeout: 120s
```

### development
Again copy `dev.env` into `.env`  

`docker compose --profile dev up`  
  
The mariadb image takes around 40 seconds to initialize. You can check the logs for the app container to see progess.

## Database  
  
The latest version of MariaDB compatible with mediawiki at the time was selected for the database. [Version compatability with mediawiki can be found here.](https://www.mediawiki.org/wiki/Special:MyLanguage/Compatibility#Database)  
  
### Users  
  
 - root: access to everything
 - wiki_app: can read/write rows to database tables. These capabilities should be able to resolve most issues
 - wiki_schema: in addition to wiki_app's priveleges, this user can also modify tables. Use with caution.

### Production Access

The docker image in the dev environment comes with a mariadb client. It can be accessed via:

```shell
docker exec -it mediawiki_db mariadb -h <HOST_IP> -u wiki_app -p
```

If using TrueNAS shell  

```shell
# as the wiki app user
sudo docker exec -it ix-mariadb-mariadb-1 mariadb -u wiki_app -p

# as root. Use with caution
sudo docker exec -it ix-mariadb-mariadb-1 mariadb -u root -p
```

To inspect the mariadb container, in the TrueNAS shell
```shell
sudo docker ps -a | grep -i mariadb
```

### Test Environment Access  
```shell
# As root
sudo docker exec -it mediawiki_db mariadb -u root -psupersecret

# Connect to the database as the app user
sudo docker exec -it mediawiki_db mariadb -u wiki_app -pappsecret wiki
```

## Test Environment App
  The wiki admin test account is `admin` with password `1234567890`.

## Common Commands  

List docker containers
```shell
sudo docker ps -a
```

### Development  
  
Show logs for the app  
```shell
sudo docker logs mediawiki_app
```
  
Run a command in the mediawiki app container
```shell
sudo docker exec -it mediawiki_app <YOUR_COMMAND_HERE>
```

Reset Containers
```shell
sudo docker compose --profile dev down -v && sudo docker compose --profile dev up -d --build
```

### Production  
  
Show logs for the app  
```shell
sudo docker logs ix-wiki-wiki-1
```

Run a command in the mediawiki app container
```shell
sudo docker exec -it ix-wiki-wiki-1 <YOUR_COMMAND_HERE>
```

Sign in to the database as root
```shell
sudo docker exec -it ix-mariadb-mariadb-1 mariadb -u root -p
```

Inspect the storage for the wiki images  
```shell
zfs list -r appdata | grep wiki
```

## Updating The App  
  
 - Make sure the image from ghcr is updated
 - Go to the TrueNAS app dashboard
 - go to Configuration -> Manage Docker Images  
 - Delete the image from ghcr
 - Go back to the app dashboard
 - Start the app
