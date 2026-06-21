<?php
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
  fwrite(STDERR, 'FAIL: One or more required environment variables are missing.\n');
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
$mysqlClient->query("FLUSH PRIVILEGES");
