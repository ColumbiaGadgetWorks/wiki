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
sudo docker exec -it ix-mariadb-mariadb-1 mariadb -u wiki_app -p
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
# dev
sudo docker compose --profile dev down -v && sudo docker compose --profile dev up -d --build

# prod
sudo docker compose --profile prod down -v && sudo docker compose --profile prod up -d --build
```
