#!/bin/bash

# Flags
export DEBUGGING=0
export NOUPGRADE=0
export NOCLEANUP=0
export NOBACKUP=0
export MOCK_DOWNLOADS=0
export RESTORE_BACKUP=0
export PAUSE=0
export HELP=0

# Data containers
export PLUGIN_TYPES=()
export PLUGINS_FOLDERS=()
export THEME_VERSION_OPTIONS=( "./moodle-upgrader/upgrade/temp/mb2nl/"*.zip )
export DB_DUMP_OPTIONS=( "./moodle-upgrader/upgrade/"*.sql )
DATE=`date +%Y-%m-%d_%H-%M-%S`
export VERBOSE=""

# Custom paths
export BASE_PATH="./moodle-files/moodle/"
export ATTO_PLUGINS_PATH="lib/editor/atto/plugins/"
export DEBUG_DB_DUMP_FILE="./dbDump.sql"
export MOODLE_DOCKER_NAME="moodleApp_setName"
export DB_DOCKER_NAME="moodleDB_setName"
export LOG_FILE="./moodle-upgrader/logs/${DATE}.log"
export MOODLE_BRANCH="MOODLE_311_STABLE" # check github.com/moodle/moodle/branches

#
export CUSTOM_THEME_NAME="mb2nl"
export CUSTOM_THEME_URL=""


# Colors
export DGREEN='\033[0;32m'
export LGREEN='\033[1;32m'
export DEBUG='\033[0;34m'
export RESPONSE='\033[1;32m'
export RUN='\033[0;34m'
export DOING='\033[0;33m'
export ERROR='\033[1;31m'
export RED='\033[1;31m'
export WHITE='\033[1;37m'
export R='\033[1;31m'
export G='\033[0;32m'
export A='\033[0;34m'
export N='\033[0;33m'
