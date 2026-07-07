## Installation

A file named `.env` is required to set the database credentials. `dev.env` can be copied into `.env` to create one.

### Production

These values in the `.env` copied from `dev.env` can be editied for secure database access:

 - `DATABASE_HOST`: The host for the mariaDB database.
 - `MYSQL_ROOT_PASSWORD` Change to a secure password.
 - `WIKI_ADMIN_PASSWORD` Change to a secure password.
 - `WIKI_APP_PASSWORD` Change to a secure password.
 - `WIKI_SCHEMA_PASSWORD` Change to a secure password.

`docker compose --profile prod up`  

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

## Updating The App  
  
 - Make sure the image from ghcr is updated
 - Go to the TrueNAS app dashboard
 - go to Configuration -> Manage Docker Images  
 - Delete the image from ghcr
 - Go back to the app dashboard
 - Start the app
