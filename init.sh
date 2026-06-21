#!/bin/bash

MAX_ATTEMPTS=3
INITIAL_WAIT_SECONDS=12

# Set colors if available
if test -t 1; then # if terminal
    ncolors=$(which tput > /dev/null && tput colors) # supports color
    if test -n "$ncolors" && test $ncolors -ge 8; then
        cyan="$(tput setaf 6)"
        green="$(tput setaf 2)"
        normal="$(tput sgr0)"
        red="$(tput setaf 1)"
        yellow="$(tput setaf 3)"
    fi
fi

# Colorized output
#   Param $1 string | The logging level: info, warning, or error
#   Param $2 string | The message to be logged
function log () {
  if [[ $# -lt 2 ]]; then
    echo "${red}ERROR: function log was run with insufficient parameters ${normal}"
    return
  fi
  
  case $1 in
    info)
      printf "${cyan}INFO: $2 ${normal}\n"
    ;;
    okay)
      printf "${green}OKAY: $2 ${normal}\n"
    ;;
    fail)
      printf "${red}FAIL: $2 ${normal}\n"
    ;;
    warn)
      printf "${yellow}WARN: $2 ${normal}\n"
    ;;
    *)
      echo "${red}FAIL: Unrecognized log level: $1 ${normal}"
    ;;
  esac
}

database_init () {
  local table_exists=$(mysql -h "$DATABASE_NAME" -u "$WIKI_DB_SCHEMA_USER" -p"$WIKI_DB_SCHEMA_PASSWORD" -N -B \
  -e "SHOW TABLES LIKE 'user';" "$DATABASE_NAME" 2>/dev/null)

  if [ -z "$table_exists" ]; then
    # php maintenance/run.php installPreConfigured
    php /tmp/setup_database.php
  else
    log okay "Database already initialized, skipping install"
  fi
}

exponential_backoff_database_init () {
  local attempt=1
  local wait=$INITIAL_WAIT_SECONDS

  while [ $attempt -le $MAX_ATTEMPTS ]; do
    log info "initializing database"
    database_init

    if [ $? -eq 0 ]; then
      log okay "Database initialized"
      return 0
    fi

    log warn "database init failed on attempt $attempt."

    if [ $attempt -lt $MAX_ATTEMPTS ]; then
      log info "Retrying in ${wait}s..."
      sleep $wait
      wait=$((wait * 2))
    fi

    attempt=$((attempt + 1))
  done

  log fail "All $MAX_ATTEMPTS attempts failed. Giving up."
  exit 1
}

exponential_backoff_database_init

# php maintenance/run.php update --quiet
