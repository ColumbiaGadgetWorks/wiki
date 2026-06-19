#!/bin/bash

TABLE_EXISTS=$(mysql -h "$DATABASE_NAME" -u "$WIKI_DB_SCHEMA_USER" -p"$WIKI_DB_SCHEMA_PASSWORD" -N -B \
-e "SHOW TABLES LIKE 'user';" "$DATABASE_NAME" 2>/dev/null)

if [ -z "$TABLE_EXISTS" ]; then
  # php maintenance/run.php installPreConfigured
  php /tmp/setup_database.php
else
  echo "Database already initialized, skipping install"
fi

# php maintenance/run.php update --quiet
