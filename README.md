## installation

A file named `.env` is required to set the database credentials. `dev.env` can be copied into `.env` to create one.

### production

These values in the `.env` copied from `dev.env` can be editied for secure database access:

 - `DATABASE_HOST`: The host for the mariaDB database.
 - `MYSQL_ROOT_PASSWORD` Change to a secure password.
 - `WIKI_SCHEMA_PASSWORD` Change to a secure password.
 - `WIKI_APP_PASSWORD` Change to a secure password.

run `./create_users.sh` and run the output SQL into the mariaDB console as root.

#### MariaDB
A standalone mariadb has been created for this.  

First a TrueNAS dataset was created with default settings named mariadb.

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

## Database  
  
The latest version of MariaDB compatible with mediawiki at the time was selected for the database. [Version compatability with mediawiki can be found here.](https://www.mediawiki.org/wiki/Special:MyLanguage/Compatibility#Database)  
  
### Users  
  
 - wiki_app: can read/write rows to database tables. These capabilities should be able to resolve most issues
 - wiki_schema: in addition to wiki_app's priveleges, this user can also modify tables. Use with caution.

### Production Access

When troubleshooting, first verify that the mariaDB service is running.  

The docker image in the dev environment comes with a mariadb client. It can be accessed via:

```shell
docker exec -it mediawiki_db mariadb -h <HOST_IP> -u wiki_app -p
```

On linux, the mariadb client can be installed via:
```shell
sudo apt install mariadb-client
```

Then logging in as wiki_schema which will have full access to the wiki's database.

```shell
mariadb -h <HOST_IP> -P 3306 -u wiki_app -p
```

If using TrueNAS shell  

```shell
sudo docker exec -it ix-mariadb-mariadb-1 mariadb -u wiki_app -p
```

To inspect the mariadb container,
```shell
sudo docker ps -a | grep -i mariadb
```

### Test Environment Access  
```shell
sudo docker exec -it mediawiki_db mariadb -u wiki_app -p
```

## Test Environment
  The wiki admin test account is `admin` with password `1234567890`.

### Common Commands
Reset Containers
```shell
sudo docker compose --profile dev down -v && sudo docker compose --profile dev up -d --build
```
