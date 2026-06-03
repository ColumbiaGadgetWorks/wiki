## installation

A file named `.env` is required to set the database credentials. `dev.env` can be copied into `.env` to create one.

### production
A standalone mariadb has been created for this.  
  
The current setup is a MariaDB image from the TrueNAS app store. It connects to a dataset named mariadb. The mariaDB user/group has been given ownership of this dataset via `chown -R 999:999 /mnt/data/mariadb` from the shell.

If no `.env` file exists, `dev.env` can be copied and the following values can be editied for database access:

 - `DATABASE_HOST`: The host for the mariaDB database.
 - `MYSQL_ROOT_PASSWORD` Not required. Delete this line.
 - `WIKI_SCHEMA_PASSWORD` Change to a secure password.
 - `WIKI_APP_PASSWORD` Change to a secure password.

run `./create_users.sh` and run the output SQL into the mariaDB console.

### development
copy `dev.env` into `.env`  

docker compose --profile dev up
