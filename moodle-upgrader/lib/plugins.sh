extract_plugins () {
  escribir "Descomprimiendo plugins..."
  for file in ./moodle-upgrader/upgrade/temp/plugins/*;
    do
      full_filename=$(basename $file);
      category_name=$(echo $full_filename | sed -e 's|\_.*||' | tr '[:upper:]' '[:lower:]');
      unzip_path="${category_name}"

      if [ -d !unzip_path ];
        then
          escribir "Creando directorio ${unzip_path}..."
          exeCute "mkdir ${VERBOSE} ${unzip_path}"
      fi

      if [ -d "${unzip_path}/${full_filename}" ];
        then
          escribir "Eliminando directorio ${unzip_path}/${full_filename}..."
          exeCute "rm -rf ${VERBOSE} ${unzip_path}/${full_filename}"
      fi
      exeCuteUnzip "unzip -o ./moodle-upgrader/upgrade/temp/plugins/${full_filename} -d ./moodle-upgrader/upgrade/temp/plugins/${category_name}";
      exeCute "rm -rf ${VERBOSE} ./moodle-upgrader/upgrade/temp/plugins/${full_filename}"
      if [[ ! ${PLUGIN_TYPES[*]} =~ ${category_name} ]]; then
          PLUGIN_TYPES+=("${category_name}")
      fi
      done
}

copy_plugins () {
  escribir "Agrupando plugins por su tipo..."
  for type in "${PLUGIN_TYPES[@]}";
    do
      escribir_debug "Plugin type: [$type]"
      if [ $type == "atto" ]; then
          destination="./moodle-upgrader/upgrade/temp/moodle/${ATTO_PLUGINS_PATH}/"
      elif [ ${type} == "block" ]; then
          destination="./moodle-upgrader/upgrade/temp/moodle/blocks"
      elif [ ${type} == "format" ]; then
          destination="./moodle-upgrader/upgrade/temp/moodle/course/format"
      else
          destination="./moodle-upgrader/upgrade/temp/moodle/${type}"
      fi
      escribir "Copiando plugins ${type}..."
      exeCute "cp ${VERBOSE} -r --archive ./moodle-upgrader/upgrade/temp/plugins/${type}/* ${destination}";
  done
  PLUGIN_TYPES=()
}

copy_plugins_live () {
  escribir "Moviendo plugins live..."
  for type in "${PLUGIN_TYPES[@]}";
    do
      escribir_debug "Plugin type: [$type]"
      if [ $type == "atto" ]; then
          destination="./moodle-files/moodle/${ATTO_PLUGINS_PATH}/"
      elif [ ${type} == "block" ]; then
          destination="./moodle-files/moodle/blocks"
      elif [ ${type} == "format" ]; then
          destination="./moodle-files/moodle/course/format"
      else
          destination="./moodle-files/moodle/${type}"
      fi
      escribir "Copiando plugins ${type} a ${destination}..."
      exeCute "cp ${VERBOSE} -r --archive ./moodle-upgrader/upgrade/temp/plugins/${type}/* ${destination}";
  done
  PLUGIN_TYPES=()
}

get_moodle_plugins_json () {
  escribir "Buscando plugins.json..."
  if [ -r "./moodle-upgrader/upgrade/plugins.json" ]; #FILE exists and the read permission is granted.
    then
      escribir "El archivo plugins.json esta OK";
    else
      escribir "Descargando plugins.json...";
      if [ $MOCK_DOWNLOADS -gt 0 ]
      then
        escribir_debug "Skipping download"
      else
        exeCute "wget -q -c https://download.moodle.org/api/1.3/pluglist.php -O ./moodle-upgrader/upgrade/plugins.json"
      fi
  fi
}

find_missing_plugins_manual () {
  escribir "Esperando que Moodle este operativo..."
  wait_moodle_ready
  escribir "Buscando plugins faltantes comparando el nuevo moodle-files con el anterior..."
  exeCute "docker exec -ti ${MOODLE_DOCKER_NAME} /usr/bin/php /var/www/html/admin/cli/uninstall_plugins.php --show-missing"
  exeCute "PLUGINS_FOLDERS" "docker exec -ti ${MOODLE_DOCKER_NAME} /usr/bin/php /var/www/html/admin/cli/uninstall_plugins.php --show-missing"
  missing=0
  for folder in "${PLUGINS_FOLDERS[@]}";
  do
    dir1="./moodle-files/moodle/${folder}"
    dir2="./moodle-upgrader/upgrade/temp/moodle/${folder}"
    if [ -d $dir1 ];
      then
        if [ -d $dir2 ];
          then
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

find_missing_plugins () {
  wait_moodle_ready
  escribir "Buscando plugins faltantes..."
  exeCute "MISSING_PLUGINS" "docker exec -ti ${MOODLE_DOCKER_NAME} /usr/bin/php /var/www/html/admin/cli/uninstall_plugins.php --show-missing"
  missing=0
  for plugin in ${MISSING_PLUGINS[*]};
  do
    if [[ $plugin == *_* ]]; then
      plugin_name="${plugin#*_}"
      plugin_category="${plugin%_*}"
      missing_plugins_to_download+=("$plugin")
      missing=1
      escribir "[MISSING] [${plugin_category}] ${plugin_name}"
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

download_missing_plugins () {
  escribir "Descargando plugins faltantes..."
  get_moodle_plugins_json
  for missing_plugin_to_download in ${missing_plugins_to_download[@]};
    do
      escribir_debug "Descargando: ${missing_plugin_to_download}..."
      plugin_id=$(cat ./moodle-upgrader/upgrade/plugins.json | jq '.plugins[] | select(.component == '\"$missing_plugin_to_download\"').versions | .[-1] | .id'  2>&1)
      plugin_release=$(cat ./moodle-upgrader/upgrade/plugins.json | jq '.plugins[] | select(.component == '\"$missing_plugin_to_download\"').versions | .[-1] | .release'  2>&1)
      plugin_download_url=$(cat ./moodle-upgrader/upgrade/plugins.json | jq '.plugins[] | select(.component == '\"$missing_plugin_to_download\"').versions | .[-1] | .downloadurl'  2>&1)
      if [ -z $plugin_release ]
        then
          escribir_error "[${missing_plugin_to_download}] => Plugin privado, no se encuentra en moodle.org"
        else
          escribir_debug "[${missing_plugin_to_download}] => https://moodle.org/plugins/${missing_plugin_to_download}/${plugin_release}/${plugin_id}"
          if [ -r "./moodle-upgrader/upgrade/temp/plugins/${missing_plugin_to_download}.zip" ]; #FILE exists and the read permission is granted.
            then
              escribir "El archivo ${missing_plugin_to_download}.zip esta OK";
            else
              if [ $MOCK_DOWNLOADS -gt 0 ]
              then
                escribir_debug "Skipping download"
              else
                exeCute "wget -q -c ${plugin_download_url} -O ./moodle-upgrader/upgrade/temp/plugins/${missing_plugin_to_download}.zip"
              fi
          fi
      fi
    done
    escribir "Plugins descargados!";
}
