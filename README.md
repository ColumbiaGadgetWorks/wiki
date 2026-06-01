## installation

A file named `.env` is required to set the database credentials. `dev.env` can be copied into `.env` to create one.

### production
If no `.env` file exists, `dev.env` can be copied and the following values can be editied for database access:

 - `MYSQL_ROOT_PASSWORD` Not required. Delete this line.
 - `WIKI_SCHEMA_PASSWORD` Change to secure password matching `wiki_schema` user login
 - `WIKI_APP_PASSWORD` Change to secure password matching `wiki_app` user login

### development
copy `dev.env` into `.env`  
