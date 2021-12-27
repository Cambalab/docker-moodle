#!/bin/bash

exeCute () {
  escribir "exeCute";
  save_to_var=0
  if [ $# -gt 1 ];
  then
    if [ ${1} = "MISSING_PLUGINS" ];
    then
      save_to_var=1
      shift
    fi
  fi

  command=$*;

  $* 1>/tmp/tar_stdout 2>/tmp/tar_stderr; RETCODE=$( echo ${?} );
  stdout_var=$( cat /tmp/tar_stdout )
  stderr_var=$( cat /tmp/tar_stderr )

  if [ $DEBUGGING -gt 0 ];
    then
      escribir_exeCute "${command}";
  fi

  if [ $DEBUGGING -gt 0 ];
    then
      if [ "$stdout_var" ];
        then
          if [ $RETCODE -gt 0 ];
            then
              escribir_error "${stdout_var}";
            else
              escribir_exeCute_response "${stdout_var}";
          fi
      fi
      if [ "$stderr_var" ];
        then
          if [ $RETCODE -gt 0 ];
            then
              escribir_error "${stderr_var}";
            else
              escribir_exeCute_response "${stderr_var}";
          fi
      fi

  fi
  if [ ${save_to_var} -eq "1" ];
    then
      MISSING_PLUGINS="${stdout_var}"
  fi
}

exeCuteUnzip () {
  command=$*;

  $* 1>/tmp/tar_stdout 2>/tmp/tar_stderr; RETCODE=$( echo ${?} );
  stdout_var=$( cat /tmp/tar_stdout )
  stderr_var=$( cat /tmp/tar_stderr )

  if [ $DEBUGGING -gt 0 ];
    then
      escribir_exeCute "${command}";
  fi

  if [ $DEBUGGING -gt 0 ];
    then
      if [ "$stdout_var" ];
        then
          if [ $RETCODE -gt 0 ];
            then
              escribir_error "${stdout_var}";
          fi
      fi
      if [ "$stderr_var" ];
        then
          if [ $RETCODE -gt 0 ];
            then
              escribir_error "${stderr_var}";
          fi
      fi

  fi
}

docker_exeCute () {
  command=$*
  if [ $DEBUGGING -gt 0 ];
    then
      escribir_exeCute "${command}";
  fi
  ${command}
}

draw_logo () {
  escribir_header " "
  escribir_header "[--------------------------------------------------------------------------------]"
  escribir_header ""
  escribir_header "${G} ((((("
  escribir_header "${G} (((((            ${G}     ((((("
  escribir_header "${G} (((((            ${G}     ((((("
  escribir_header "${G} (((((            ${G}     (((((          ${N}      .###########(     "
  escribir_header "${G} (((((                               ${N}   .#################/  "
  escribir_header "${G} (((((            ${R}/////////////////   ${N}  ########(   /######(  "
  escribir_header "${G} (((((            ${R}/////////////////   ${N} ######*            (*  "
  escribir_header "${G} (((((            ${G}                    ${N}######                  "
  escribir_header "${G} (((((            ${G}     (((((          ${N}######                  "
  escribir_header "${G} (((((            ${G}     ((((("
  escribir_header "${G} (((((            ${G}     (((((          ${N}######                  "
  escribir_header "${G} (((((            ${G}     (((((          ${N}*######                 "
  escribir_header "                  ${G}     ((((((         ${N} *#######.      *####.  "
  escribir_header "${A} /////////////////${G}     ((((((((((((   ${N}   ###################  "
  escribir_header "${A} /////////////////${G}      (((((((((((   ${N}     /##############    "

  escribir_header "${G}"
  escribir_header "https://ltc.camba.coop    educacion@camba.coop    Un proyecto de Camba.coop "
  escribir_header " "
  if [ $DEBUGGING -gt 0 ]; then DEBUG_STATUS="DEBUG MODE IS ON"; else DEBUG_STATUS="DEBUG MODE IS OFF"; fi
  if [ $PAUSE -gt 0 ]; then PAUSE_STATUS="PAUSE MODE IS ON"; else PAUSE_STATUS="PAUSE MODE IS OFF"; fi
  if [ $NOUPGRADE -gt 0 ]; then NOUPGRADE_STATUS="NOUPGRADE MODE IS ON"; else NOUPGRADE_STATUS="NOUPGRADE MODE IS OFF"; fi
  escribir_header "    [${DEBUG_STATUS}]  [${PAUSE_STATUS}]  [${NOUPGRADE_STATUS}]    "
  escribir_header " "
  escribir_header "[--------------------------------------------------------------------------------]"
  escribir_header "[-----------------------------{ ${DATE} }----------------------------]"
  escribir_header "[--------------------------------------------------------------------------------]"
  escribir_header " ${WHITE}"
}

bienvenida () {
  if [ $DEBUGGING -gt 0 ]
    then
      escribir_debug "Salteando bienvenida..."
    else
      escribir "Hola!"
      escribir "Este script se encargara de actualizar Moodle."
      escribir "Pero antes de continuar:"
      escribir " 1. Descarga la version de Moodle y coloca el archivo comprimido dentro de la carpeta ./moodle-upgrader/upgrade/ con el nombre moodle.tgz"
      escribir " 2. De igual manera, descarga el theme MB2Nl desde themeforest y colocalo en ./moodle-upgrader/upgrade/ con el nombre mb2nl.zip"
      escribir "¿Ya tenes todo listo?"
      escribir " ";
      read -n 1 -s -r -e -p "Presiona cualquier tecla para continuar... "
      escribir " "
  fi
}

pause () {
  if [ "$PAUSE" -gt 0 ]
    then
      read -n 1 -s -r -e -p "Presiona cualquier tecla para continuar..."
  fi
}

rollback () {
  escribir "Restaurando copias de seguridad..."
  exeCute "rm -rf ${VERBOSE} ./moodle-files/"
  exeCute "rm -rf ${VERBOSE} ./moodle-files/"
}

actualizar () {
  pause
  detener_contenedores
  pause
  startup_temp
  pause
  if [ $RESTORE_BACKUP -gt 0 ];
    then
      restore_moodle_files
    else
      backup_moodle_files
  fi
  pause
  # extract_moodle
  get_moodle
  pause
  # get_eletece_theme
  pause
  extract_mb2nl
  pause
  copy_themes
  pause
  update_db
  # pause
  update_moodle_folder
  pause
  start_containers # acá llega
  pause
  find_missing_plugins # acá llega
  pause
  extract_plugins
  pause
  detener_contenedores
  pause
  copy_plugins
  pause
  update_moodle_folder
  pause
  start_containers
  pause
  check_moodle_folder
  pause
  update_folder_permissions
  pause
  perform_upgrade
  moodle_set_admin_password
  pause
  cleanup
}

copy_themes () {
  escribir "Copiando themes a la nueva version de moodle..."
  exeCute "cp ${VERBOSE} --archive ./moodle-upgrader/upgrade/theme/* ./moodle-upgrader/upgrade/temp/moodle/theme/"
}

detener_contenedores () {
  escribir "Deteniendo los contenedores con docker-compose down..."
  exeCute "docker-compose down"
  if [ $? -eq 0 ];
    then
      escribir "Contenedores detenidos";
    else
      escribir_error "Hubo algun problema al detener los contenedores";
      exit 1
  fi
}

clear_logs () {
  escribir "Eliminando logs..."
  exeCute "rm -rf .moodle-upgrader/logs/*.log"
}

start () {
  draw_logo
  # [[ $EUID -ne 0 ]] && escribir_error "Este script necesita ser ejecutado como root!" && exit 1
  bienvenida
  actualizar
  despedir
}

startup_temp () {
  (cd ./moodle-upgrader/logs && ls -tp | grep -v '/$' | tail -n +6 | tr '\n' '\0' | xargs -0 rm --)
  if [ -d "./moodle-upgrader/upgrade/" ];
    then
      escribir "Carpeta ./moodle-upgrader/upgrade/theme/eletece OK"
    else
      escribir_error "No se pudo encontrar la carpeta ./moodle-upgrader/upgrade y es necesaria."
      escribir_error "Para mas informacion ejecuta el script con el parametro --help"
      exit 1
  fi

  if [ -d "./moodle-upgrader/upgrade/temp" ];
    then
      escribir "Eliminando directorio ./moodle-upgrader/upgrade/temp..."
      exeCute "rm -rf ${VERBOSE} ./moodle-upgrader/upgrade/temp"
      escribir "Recreando directorio ./moodle-upgrader/upgrade/temp..."
      exeCute "mkdir ${VERBOSE} ./moodle-upgrader/upgrade/temp"
    else
      escribir "Creando directorio ./moodle-upgrader/upgrade/temp..."
      exeCute "mkdir ${VERBOSE} ./moodle-upgrader/upgrade/temp"
  fi

  if [ -d "./backups" ];
    then
      escribir "Carpeta backups esta OK."
    else
      escribir "Creando carpeta /backups/..."
      exeCute "mkdir ${VERBOSE} ./backups"
  fi

  if [ -d "./moodle-upgrader/upgrade/temp/plugins" ];
    then
      escribir "Eliminando directorio ./moodle-upgrader/upgrade/temp/plugins..."
      exeCute "rm -rf ${VERBOSE} ./moodle-upgrader/upgrade/temp/plugins"
      escribir "Creando directorio ./moodle-upgrader/upgrade/temp/plugins.."
      exeCute "mkdir ${VERBOSE} ./moodle-upgrader/upgrade/temp/plugins"
    else
      escribir "Creando directorio ./moodle-upgrader/upgrade/temp/plugins..."
      exeCute "mkdir ${VERBOSE} ./moodle-upgrader/upgrade/temp/plugins"
  fi

  if [ -d "./moodle-upgrader/upgrade/temp/mb2nl" ];
    then
      escribir "Carpeta ./moodle-upgrader/upgrade/temp/mb2nl OK"
    else
      escribir "Creando carpeta ./moodle-upgrader/upgrade/temp/mb2nl..."
      exeCute "mkdir ${VERBOSE} ./moodle-upgrader/upgrade/temp/mb2nl"
  fi

  if [ -d "./moodle-upgrader/upgrade/temp/mb2nl/Plugins" ];
    then
      escribir "Carpeta ./moodle-upgrader/upgrade/temp/mb2nl/Plugins OK"
    else
      escribir "Creando carpeta ./moodle-upgrader/upgrade/temp/mb2nl/Plugins..."
      exeCute "mkdir ${VERBOSE} ./moodle-upgrader/upgrade/temp/mb2nl/Plugins"
  fi

  if [ -d "./moodle-upgrader/upgrade/theme" ];
    then
      escribir "Carpeta ./moodle-upgrader/upgrade/theme OK"
    else
      escribir "Creando carpeta ./moodle-upgrader/upgrade/theme..."
      exeCute "mkdir ${VERBOSE} ./moodle-upgrader/upgrade/theme"
  fi

  if [ -d "./moodle-upgrader/upgrade/theme/eletece" ];
    then
      escribir "Carpeta ./moodle-upgrader/upgrade/theme/eletece OK"
    else
      escribir "Creando carpeta ./moodle-upgrader/upgrade/theme/eletece..."
      exeCute "mkdir ${VERBOSE} ./moodle-upgrader/upgrade/theme/eletece"
  fi

}

restore_moodle_files () {
  exeCute "Eliminando ./moodle-files/moodle/...";
  exeCute "rm -rf ${VERBOSE} ./moodle-files/moodle/"
  escribir "Restaurando backup..."
  exeCuteUnzip "unzip -o ./moodle-upgrader/backups/moodle-files.zip -d ./moodle-files/moodle/";
}

clone_original_moodle_files () {
  if [ -d $BASE_PATH ];
    then
      escribir "Clonando moodle-files..."
      exeCute "cp ${VERBOSE} --archive ${BASE_PATH} ./moodle-upgrader/upgrade/temp/moodle-files-original"
    else
      escribir_error "No se encuentra la carpeta ${BASE_PATH}";
      exit 1
    fi
}

backup_moodle_files () {
  escribir "Creando respaldo de moodle-files..."
  if [ $NOBACKUP -gt 0 ];
    then
      escribir_debug "Salteando creacion de copia de seguridad de moodle-files..."
    else
      escribir_debug "Creando copia de seguridad de moodle-files..."
      if [ -d $BASE_PATH ];
        then
          if [ -r "./moodle-upgrader/backups/moodle-files.zip" ]; #FILE exists.
            then
              escribir "moodle-files.zip backup ya existe, eliminando backup previo..."
              exeCute "rm -rf ${VERBOSE} ./moodle-upgrader/backups/moodle-files.zip"
          fi
          clone_original_moodle_files
          escribir "Creando nuevo backup de moodle-files..."
          exeCute "zip -r -T ./moodle-upgrader/backups/moodle-files.zip ${BASE_PATH}"
        else
          escribir_error "No se encuentra la carpeta ${BASE_PATH}";
          exit 1
        fi
  fi
}

extract_moodle () {
  escribir "Extrayendo Moodle..."
  if [ -r "./moodle-upgrader/upgrade/moodle.tgz" ]; #FILE exists and the read permission is granted.
    then
      exeCute "tar -xzf ./moodle-upgrader/upgrade/moodle.tgz -C ./moodle-upgrader/upgrade/temp/"
    else
      escribir_error "No se encontro el archivo moodle.tgz en la carpeta upgrade";
  fi
}

update_moodle_folder () {
  escribir "Actualizando moodle-files con la version actualizada...";
  escribir_debug "[Actualizando moodle-files/moodle con la nueva version...]"
  escribir_debug "Eliminando carpeta ./moodle-files/moodle...";
  exeCute "rm -rf ${VERBOSE} ./moodle-files/moodle/"
  escribir "Copiando ./moodle-upgrader/upgrade/temp/moodle/ a ./moodle-files/moodle...";
  exeCute "cp ${VERBOSE} --archive ./moodle-upgrader/upgrade/temp/moodle/ ./moodle-files/moodle"
}

update_folder_permissions () {
  escribir "[!!!!] Configurando permisos de archivos y carpetas para ./moodle-files/moodle...";
  escribir_debug "[Actualizando permisos...]"
  # exeCute "chown -R www-data:www-data ./moodle-files/moodle"
  # exeCute "chmod 755 -R ./moodle-files/moodle"
  # exeCute "tar -xzf ./moodle-upgrader/upgrade/moodle.tgz -C ./moodle-upgrader/upgrade/temp/"
  # exeCute "chown -R www-data:www-data ./moodle-data-backup"
  # exeCute "chmod 700 -R ./moodle-data-backup"
}

update_db () {
  escribir "Actualizando dump de la base de datos..."
  if [ -r "./dbDump.sql" ]; #FILE exists and the read permission is granted.
    then
      escribir "Backupeando archivo dbDump.sql...";
      exeCute "cp ${VERBOSE} --archive ./dbDump.sql ./moodle-upgrader/backups/dbDump.sql"
      if [ $DEBUGGING -gt 0 ]
        then
          db_dump_version_selected=$DEBUG_DB_DUMP_FILE;
        else
          PS3='Que dump de SQL queres usar? Ingresa el numero o 0 para salir: '
          select db_dump_version_selected in "${DB_DUMP_OPTIONS[@]}"; do
            if [[ $REPLY == "0" ]]; then
              echo 'Bye!' >&2
              break
            elif [[ -z $db_dump_version_selected ]]; then
              echo 'Invalid choice, try again' >&2
            fi
          done
      fi
      if [ -r "${db_dump_version_selected}" ]; #FILE exists and the read permission is granted.
        then
          escribir "Actualizando archivo dbDump.sql con ${db_dump_version_selected}...";
          exeCute "cp ${VERBOSE} -f ${db_dump_version_selected} ./dbDump.sql"
        else
          escribir "WARNING: No se encuentra un archivo ${db_dump_version_selected} en ./moodle-upgrader/upgrade/";
      fi

    else
      escribir_error "No se encuentra el archivo dbDump.sql";
  fi
}

get_eletece_theme () {
  if [ -d "./moodle-upgrader/upgrade/temp/eletece" ];
    then
      escribir "La carpeta ./moodle-upgrader/upgrade/temp/eletece esta ok"
    else
      escribir "Creando la carpeta ./moodle-upgrader/upgrade/temp/eletece..."
      exeCute "mkdir ${VERBOSE} ./moodle-upgrader/upgrade/temp/eletece"
  fi

  escribir "Descargando theme eletece..."
  if [ $MOCK_DOWNLOADS -gt 0 ]
  then
    escribir_debug "Skipping download"
  else
    exeCute "wget -q -c ${CUSTOM_THEME_URL} -O ./moodle-upgrader/upgrade/temp/eletece.zip"
  fi
  if [ -r "./moodle-upgrader/upgrade/temp/eletece.zip" ]; #FILE exists and the read permission is granted.
    then
      escribir "Extrayendo theme eletece..." # TODO: Dinamizar themes
      exeCuteUnzip "unzip -o ./moodle-upgrader/upgrade/temp/eletece.zip -d ./moodle-upgrader/upgrade/temp/";
      escribir "Moviendo theme eletece..." # TODO: Dinamizar themes
      exeCute "cp ${VERBOSE} --archive ./moodle-upgrader/upgrade/temp/eletece-*/* ./moodle-upgrader/upgrade/theme/eletece"
      # exeCute "mkdir ${VERBOSE} ./moodle-upgrader/upgrade/theme/eletece"\ \
      # "cp ${VERBOSE} --archive ./moodle-upgrader/upgrade/temp/eletece-master-*/* ./moodle-upgrader/upgrade/theme/eletece"
    else
      escribir_error "No se encontro el archivo ./moodle-upgrader/upgrade/temp/eletece.zip";
  fi
}

match_themes() {
  # No anda,
  escribir "Buscando diferencias en los archivos de la nueva version de los temas instalados y la version previa..."
  for folder in "${PLUGINS_FOLDERS[@]}";
    do
      dir1="./moodle-files/moodle/theme/eletece"
      dir2="./moodle-files/moodle/theme/mb2nl"
      escribir "Comparando ${dir2} vs ${dir1}"
      if [ -d $dir1 ];
        then
          if [ -d $dir2 ];
            then
              escribir_debug comm -1 -3 <(ls $dir2 | sort) <(ls $dir1 | sort)
              for plugin in $(comm -1 -3 <(ls $dir2 | sort) <(ls $dir1 | sort));
                do
                  missing=1
                  escribir "- The plugin ${DEBUG}${plugin}${NC} is missing from the ${DEBUG}${folder}${NC} directory "
                  plugin_name=$(cat $dir1/$plugin/version.php | grep 'plugin->component' | cut -d "'" -f 2 2>&1)
                  missing_plugins_to_download+=("$plugin_name")
                done
          fi
      fi
    done
    if [ $missing -gt 0 ]
      then
        while true; do
          escribir "¿Queres que descarguemos los plugins que faltan?"
          read -p "$* [s/n]: " yn
          case $yn in
            [Ss]*) download_missing_plugins && break ;;
            [Nn]*) break ;;
          esac
        done
    fi
}

extract_mb2nl () {
  escribir "Extrayendo theme mb2nl..." # TODO: Dinamizar themes
  if [ -r "./moodle-upgrader/upgrade/mb2nl.zip" ]; #FILE exists and the read permission is granted.
    then
      exeCuteUnzip "unzip -o ./moodle-upgrader/upgrade/mb2nl.zip -d ./moodle-upgrader/upgrade/temp/mb2nl";
    else
      escribir_error "No se encontro el archivo ./moodle-upgrader/upgrade/mb2nl.zip";
      exit 1
  fi
  if [ $DEBUGGING -gt 0 ]
  then
    echo "Salteando warning...";
  else
    escribir " ";
    escribir " ";
    escribir "${R}[ATENCION!]${WHITE}";
    escribir "    Si se realizaron cambios manuales en el tema, tendras que actualizarlos de forma manual en la nueva version.";
    escribir "    Podes realizar los cambios sobre el tema ubicado en este momento en ./moodle-upgrader/upgrade/temp/mb2nl";
    escribir "    o tambien podes ignorar este mensaje y aplicar los cambios sobre el tema una vez finalizada la actualizacion.";
    escribir "    Para continuar ingresa Y o si queres cancelar este proceso, ingresa N para finalizar.";
    escribir "${R}[ATENCION!]${WHITE}";
    escribir " ";
    escribir " ";
    while true; do
      read -p "$* [s/n]: " yn
      case $yn in
        [Ss]*) break ;;
        [Nn]*) escribir "Aborted" ; exit  1 ;;
      esac
    done
  fi
  escribir "moviendo los plugins de mb2nl..."
  find ./moodle-upgrader/upgrade/temp/mb2nl/Plugins -type f -name "*.zip" -exec cp ${VERBOSE} --archive {} "./moodle-upgrader/upgrade/temp/plugins/" \;

  if [ $? -eq 0 ];
    then
      escribir "MB2NL EXTRAIDO OK";
    else
      escribir_error "No se pudo copiar el plugin de ./moodle-upgrader/upgrade/temp/mb2nl/Plugins";
      exit 1
  fi

  if [ $DEBUGGING -gt 0 ]
    then
      theme_version_selected="./moodle-upgrader/upgrade/temp/mb2nl/theme_mb2nl-6.0.0_MOODLE-3.8-3.11.zip"
    else
      PS3='Que version del tema queres usar? Ingresa un numero o 0 para salir: '
      select theme_version_selected in "${THEME_VERSION_OPTIONS[@]}"; do
          if [[ $REPLY == "0" ]]; then
              echo 'Bye!' >&2
              break
          elif [[ -z $theme_version_selected ]]; then
              echo 'Invalid choice, try again' >&2
          else
              break
          fi
      done
  fi
  escribir "Extrayendo ${theme_version_selected}..."
  exeCuteUnzip "unzip -o ${theme_version_selected} -d ./moodle-upgrader/upgrade/theme/";
}

cleanup () {
  escribir "Eliminando archivos no necesarios..."
  if [ $NOCLEANUP -gt 0 ];
    then
      escribir "Salteando cleanup..."
    else
      escribir "Purgando ./moodle-upgrader/upgrade/moodle..."
      exeCute "rm -rf ${VERBOSE} ./moodle-upgrader/upgrade/moodle/"
      escribir "Purgando ./moodle-upgrader/upgrade/temp..."
      exeCute "rm -rf ${VERBOSE} ./moodle-upgrader/upgrade/temp/"
      escribir "Purgando ./moodle-upgrader/upgrade/theme..."
      exeCute "rm -rf ${VERBOSE} ./moodle-upgrader/upgrade/theme/"
      escribir "Purgando ./moodle-upgrader/upgrade/mb2nl..."
      exeCute "rm -rf ${VERBOSE} ./moodle-upgrader/upgrade/mb2nl/"
      escribir "Listo!"
  fi
}

despedir () {
  if [ $DEBUGGING -gt 0 ];
    then
      escribir "Salteando despedida..."
    else
      escribir "Actualizacion finalizada, ahora ingresa en http://localhost/admin/"
      escribir "Confirma la nueva configuracion y revisa que todo funcione bien,"
      escribir "Que los plugins funcionen como correctamente y que las modificaciones manuales del código esten funcionando."
      escribir "Suerte!"
  fi
  exit 0
}

start_containers () {
  escribir "Inicializando los contenedores con docker-compose..."
  exeCute "docker-compose up -d"
}

perform_upgrade () {
  if [ $NOUPGRADE -gt 0 ]
    then
      echo "Salteando actualizacion con moodle...";
    else
      escribir "Comenzando actualizacion de version de moodle...";
      escribir "Esperando a que los contenedores esten listo..."
      wait_moodle_ready
      escribir "Iniciando upgrade con moodle_cli..."
      docker_exeCute "docker exec -ti ${MOODLE_DOCKER_NAME} /usr/bin/php /var/www/html/admin/cli/upgrade.php"
      escribir "Purgando caches..."
      docker_exeCute "docker exec -ti ${MOODLE_DOCKER_NAME} /usr/bin/php /var/www/html/admin/cli/purge_caches.php"
  fi
}

check_moodle_folder () {
  escribir "Chequeando nueva carpeta moodle"
  escribir "Version instalada:"
  exeCute "cat ./moodle-files/moodle/version.php | grep '${plugin_release}' | cut -d\"'\" -f2"
  escribir "${WHITE}Moodle check:${N}"
  docker_exeCute "docker exec -ti ${MOODLE_DOCKER_NAME} /usr/bin/php /var/www/html/admin/cli/checks.php --verbose"
  escribir "${WHITE}Build theme css:${N}"
  docker_exeCute "docker exec -ti ${MOODLE_DOCKER_NAME} /usr/bin/php /var/www/html/admin/cli/build_theme_css.php --verbose"
  escribir "${WHITE}Temas instalados:${N}"
  exeCute "ls -1a -d ./moodle-files/moodle/theme/"'*'"/ | xargs -n 1 basename"
}

usage () {
  escribir " "
  escribir "Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]"
  escribir " "
  escribir "Script description here."
  escribir " "
  escribir "Available options:"
  escribir "-start, --start     Start the upgrade process."
  escribir "-nu, --no-upgrade     Skip the actual Moodle upgrade step."
  escribir "-nc, --no-cleanup     Don't erase the temp folder content."
  escribir "-nb, --no-backup     Don't backup db nor moodle files."
  escribir "-rb, --restore-backup     Restore the backup instead of making a new one."
  escribir "-v, --verbose     Make the debug messages more verboses."
  escribir "-bmf, --backup-moodle-files     Backup moodle-files folder and exit."
  escribir "-emb2nl, --extract-mb2nl     extract_mb2nl && exit"
  escribir "-s, --startup     Initialize the temporal folder, create the folders and exit."
  escribir "-u, --upgrade     Perform the Moodle upgrade and exit."
  escribir "-msd, --moodle_show_debugging     Show Moodle debugging. [experimental]"
  escribir "-msq, --moodle_show_querys     Show Moodle db querys.  [experimental]"
  escribir "-fmp, --find-missing-plugins     Busca plugins faltantes en la instalacion actual."
  escribir "-fmpm, --find-missing-plugins-manual      startup_temp && extract_mb2nl && find_missing_plugins_manual && download_missing_plugins && extract_plugins && copy_plugins_live && exit;;"
  escribir "--exeCute [function]      Execute a function from the lib and exit"
  escribir "-c, --clean     Erase the temp folder content and exit."
  escribir "-md, --mock-downloads     Fake downloads."
  escribir "-h, --help      Print this help and exit"
  escribir "-p, --pause     Stop after each function block"
  escribir "-d, --debug     Display some extra info about process running"
  escribir " "
  exit
}

wait_moodle_ready () {
  escribir "Esperando que Moodle este listo..."
  until $(curl --output /dev/null --silent --head --fail http://localhost/admin/); do     echo -n -e "${N}.";     sleep 5; done;
  escribir "Moodle esta listo!"
}

get_moodle () {
  escribir "Descargando Moodle via GIT"
  if [ $MOCK_DOWNLOADS -gt 0 ]
  then
    escribir_debug "Skipping download"
  else
    exeCute "git clone --depth 1 --branch ${MOODLE_BRANCH} https://github.com/moodle/moodle.git ./moodle-upgrader/upgrade/temp/moodle"
  fi
}

moodle_set_admin_password () {
  escribir "Esperando que Moodle este operativo..."
  wait_moodle_ready
  escribir "Cambiando contraseña del admin..."
  exeCute "docker exec -ti ${MOODLE_DOCKER_NAME} /usr/bin/php /var/www/html/admin/cli/reset_password.php -u=admin -p=pass --ignore-password-policy"
  escribir "La nueva contraseña del admin es 'pass'..."
}

moodle_reset_password () {
  escribir "Esperando que Moodle este operativo..."
  wait_moodle_ready
  escribir "Cambiar clave de usuario..."
  exeCute "docker exec -ti ${MOODLE_DOCKER_NAME} /usr/bin/php /var/www/html/admin/cli/reset_password.php"
}

moodle_show_querys () {
  escribir "Esperando que Moodle este operativo..."
  wait_moodle_ready
  exeCute "docker exec -ti ${MOODLE_DOCKER_NAME} /usr/bin/php /var/www/html/admin/cli/adhoc_task.php --showsql --force"
  exeCute "docker logs ${MOODLE_DOCKER_NAME} --timestamps --follow"
}

moodle_show_debugging () {
  escribir "Esperando que Moodle este operativo..."
  wait_moodle_ready
  exeCute "docker exec -ti ${MOODLE_DOCKER_NAME} /usr/bin/php /var/www/html/admin/cli/adhoc_task.php --showdebugging"
  exeCute "docker logs ${MOODLE_DOCKER_NAME} --timestamps --follow"
}

dump_database () {
  escribir "Esperando que Moodle este operativo..."
  wait_moodle_ready
  escribir "Creando dumpy..."
  full_path=$(realpath $0)
  dir_path=$(dirname $full_path)
  examples=$(dirname $dir_path )
  data_dir="$examples/data"
  echo "${dir_path}/dbDump.sql"

# exeCute "docker exec -ti --privileged moodleDB_setName mysqldump -umoodle –pmoodle moodle < /tmp/dbDump.sql"
  exeCute "docker exec -u root ${DB_DOCKER_NAME} /usr/bin/mysqldump -u root --password=${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE}"
  exeCute "docker exec ${DB_DOCKER_NAME} pwd"
  # exeCute "docker cp ${DB_DOCKER_NAME}:${dir_path}/dbDump.sql.new /tmp/dbDump.sql"
  escribir "Listo!"
}
