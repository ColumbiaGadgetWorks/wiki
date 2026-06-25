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

create_database_resources () {
  php /tmp/setup_database.php
}

exponential_backoff_create_database_resources () {
  local attempt=1
  local wait=$INITIAL_WAIT_SECONDS

  while [ $attempt -le $MAX_ATTEMPTS ]; do
    log info 'Initializing database'
    create_database_resources

    if [ $? -eq 0 ]; then
      log okay 'Database initialized'
      return 0
    fi

    log warn "Database init failed on attempt $attempt."

    if [ $attempt -lt $MAX_ATTEMPTS ]; then
      log info "Retrying in ${wait}s..."
      sleep $wait
      wait=$((wait * 2))
    fi

    attempt=$((attempt + 1))
  done

  return 1
}

update_mediawiki () {
  log info 'Updating'

  if ! php maintenance/run.php update --quiet; then
    log fail 'MediaWiki update failed, aborting startup' >&2
    exit 1
  fi
}

CREATE_DATABASE_RESOURCES_RESULT=$(exponential_backoff_create_database_resources | tee /dev/tty)

if [ $? -ne 0 ]; then
  log fail "Maximum number of attempts failed. Exiting."
  log info "$CREATE_DATABASE_RESOURCES_RESULT"
  exit 1
fi

log info "$CREATE_DATABASE_RESOURCES_RESULT"

if echo "$CREATE_DATABASE_RESOURCES_RESULT" | grep -q 'A user table was found'; then
  log info 'A user table was found in the database and the database is assumed to be set up.'

  update_mediawiki
elif echo "$CREATE_DATABASE_RESOURCES_RESULT" | grep -q 'A user table was not found'; then
  log info 'A user table was not found in the database and the schema is assumed to be not set up.'

  log info 'Setting up schema'
  php maintenance/run.php installPreConfigured "$WIKI_ADMIN_USER" "$WIKI_ADMIN_PASSWORD"

  log info 'Creating admin user'
  php maintenance/run.php createAndPromote --bureaucrat --sysop --force "$WIKI_ADMIN_USER" "$WIKI_ADMIN_PASSWORD"

  update_mediawiki
else
  log fail 'Failed to assess status of database. Exiting'
  exit 1
fi

exec apache2-foreground
