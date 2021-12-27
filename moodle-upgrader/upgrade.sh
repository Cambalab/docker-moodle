#!/bin/bash
#
#     Este script fue creado por Damian Mantuano para la Cooperativa Cambá
#     Conoce mas sobre cambá en https://camba.coop
#
#     Si tenes dudas escribime a
#     smarbos@gmail.com
#
#     Tambien podes crear un issue en nuestro repo:
#     XXXXXXXXXXX
#
#     O podes forkearlo y adaptarlo a tus necesidades:
#     XXXXXXXXXXX
#
#     Siempre compartiendo el código fuente!
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details:
#
#         http://www.gnu.org/copyleft/gpl.html
#
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
#   detener_contenedores () {
#   escribir "Deteniendo los contenedores con docker-compose down..."
#   docker ps | grep "moodlePlataforma";
#   exeCute "docker-compose down" }
#
#   IFS=$space$tab$newline
#
#
#   docker exec -ti moodlePlataforma /usr/bin/php /var/www/html/admin/cli/checks.php -v
#   docker exec -ti moodlePlataforma /usr/bin/php /var/www/html/admin/cli/uninstall_plugins.php --show-missing
#
#
#
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Include vars and configuration
echo "Starting"
if [ -f moodle_variables.env ]
then
  export $(cat moodle_variables.env | sed 's/#.*//g' | xargs)
fi
echo "Loading ${PROYECT_NAME}"

source "./moodle-upgrader/lib/vars.sh"

# Include plugins methods
source "./moodle-upgrader/lib/plugins.sh"

# Include main methods
source "./moodle-upgrader/lib/main.sh"

source "./moodle-upgrader/lib/write.sh"

while :; do
  case "${1-}" in
    -d | --debug) DEBUGGING=1 ;;
    -start | --start) start && exit ;;
    -nu | --no-upgrade) NOUPGRADE=1 ;;
    -nc | --no-cleanup) NOCLEANUP=1 ;;
    -nb | --no-backup) NOBACKUP=1 ;;
    -rb | --restore-backup) RESTORE_BACKUP=1 ;;
    -md | --mock-downloads) MOCK_DOWNLOADS=1 ;;
    -ddb | --dump-db) dump_database && exit ;;
    -p | --pause) PAUSE=1 ;;
    -v | --verbose) VERBOSE="--verbose" ;;
    -bmf | --backup-moodle-files) backup_moodle_files && exit ;;
    -emb2nl | --extract-mb2nl) extract_mb2nl && exit ;;
    -h | --help) usage ;;
    -s | --startup) startup_temp && exit ;;
    -u | --upgrade) perform_upgrade && exit ;;
    -msd | --moodle_show_debugging) moodle_show_debugging && exit ;;
    -msq | --moodle_show_querys) moodle_show_querys && exit ;;
    -fmp | --find-missing-plugins) startup_temp && extract_mb2nl && find_missing_plugins && download_missing_plugins && extract_plugins && copy_plugins_live && exit;;
    -fmpm | --find-missing-plugins-manual ) startup_temp && extract_mb2nl && find_missing_plugins_manual && download_missing_plugins && extract_plugins && copy_plugins_live && exit;;
    --exeCute ) exeCute $@ && exit ;;
    -c | --clean) cleanup && exit ;;
    -?*) echo "Unknown option: $1" ;;
    *) echo "Use --help to see options" && exit ;;
  esac
  shift
done
