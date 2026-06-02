#!/bin/bash
print=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p) print=true ;;
    --print) print=true ;;
  esac
  shift
done

source .env

if $print; then
  cat <<EOF
CREATE USER IF NOT EXISTS '$WIKI_SCHEMA_USER'@'%' IDENTIFIED BY '$WIKI_SCHEMA_PASSWORD';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX ON $DATABASE_NAME.* TO '$WIKI_SCHEMA_USER'@'%';

CREATE USER IF NOT EXISTS '$WIKI_APP_USER'@'%' IDENTIFIED BY '$WIKI_APP_PASSWORD';
GRANT SELECT, INSERT, UPDATE, DELETE ON $DATABASE_NAME.* TO '$WIKI_APP_USER'@'%';
EOF
else
  echo "no"
fi
