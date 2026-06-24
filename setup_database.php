<?php
// Using the php mysql client saves resources from installing a command line mysql client

$envVariables = [];

$envVariables['DATABASE_HOST'] = getenv('DATABASE_HOST');
$envVariables['DATABASE_NAME'] = getenv('DATABASE_NAME');
$envVariables['MYSQL_ROOT_PASSWORD'] = getenv('MYSQL_ROOT_PASSWORD');
$envVariables['WIKI_DB_APP_USER'] = getenv('WIKI_DB_APP_USER');
$envVariables['WIKI_DB_APP_PASSWORD'] = getenv('WIKI_DB_APP_PASSWORD');
$envVariables['WIKI_DB_SCHEMA_USER'] = getenv('WIKI_DB_SCHEMA_USER');
$envVariables['WIKI_DB_SCHEMA_PASSWORD'] = getenv('WIKI_DB_SCHEMA_PASSWORD');

$missingEnvVariables = implode(', ', array_keys($envVariables, false, true));

if (strlen($missingEnvVariables)) {
  fwrite(STDERR, "FAIL: One or more required environment variables are missing.\n");
  fwrite(STDERR, "  Missing variables are: {$missingEnvVariables}\n");
  exit(1);
}

$mysqlClient = new mysqli($envVariables['DATABASE_HOST'], 'root', $envVariables['MYSQL_ROOT_PASSWORD']);

$mysqlClient->query("CREATE DATABASE IF NOT EXISTS {$envVariables['DATABASE_NAME']};");

if ($mysqlClient->error) {
  fwrite(STDERR, "FAIL: failed to create wiki database\n");
  fwrite(STDERR, "  " . $mysqlClient->error . "\n");
}

$mysqlClient = new mysqli($envVariables['DATABASE_HOST'], 'root', $envVariables['MYSQL_ROOT_PASSWORD']);

$mysqlClient->query("CREATE USER IF NOT EXISTS '{$envVariables['WIKI_DB_SCHEMA_USER']}'@'%' IDENTIFIED BY '{$envVariables['WIKI_DB_SCHEMA_PASSWORD']}';");

if ($mysqlClient->error) {
  fwrite(STDERR, "FAIL: failed to create user with schema modification privileges\n");
  fwrite(STDERR, "  " . $mysqlClient->error . "\n");
}

$mysqlClient->query("GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX ON {$envVariables['DATABASE_NAME']}.* TO '{$envVariables['WIKI_DB_SCHEMA_USER']}'@'%';");

$mysqlClient->query("CREATE USER IF NOT EXISTS '{$envVariables['WIKI_DB_APP_USER']}'@'%' IDENTIFIED BY '{$envVariables['WIKI_DB_APP_PASSWORD']}';");

if ($mysqlClient->error) {
  fwrite(STDERR, "FAIL: failed to create user for reading/writing rows\n");
  fwrite(STDERR, "  " . $mysqlClient->error . "\n");
}

$mysqlClient->query("GRANT SELECT, INSERT, UPDATE, DELETE ON {$envVariables['DATABASE_NAME']}.* TO '{$envVariables['WIKI_DB_APP_USER']}'@'%';");
$mysqlClient->query('FLUSH PRIVILEGES');

$mysqlClient->select_db($envVariables['DATABASE_NAME']);
$schemaInitTest = $mysqlClient->query("SHOW TABLES LIKE 'user'");

if ($schemaInitTest->num_rows > 0) {
  fwrite(STDOUT, "INFO: A user table was found in the database and the schema is assumed to be set up.\n");
} else {
  fwrite(STDOUT, "INFO: A user table was not found in the database and the schema is assumed to be not set up.\n");
}
