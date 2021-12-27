# moodle-upgrader

Este programa permite automatizar la actualización de las implementaciones de Moodle que gestionamos desde Cambá.
Esta pensado para utilizar en conjunto con un ambiente de desarrollo que utiliza docker-compose para orquestar el contenedor que corre Moodle y el de la base de datos.
La carpeta de este programa debe incluirse dentro del directorio del ambiente de desarrollo antes mencionado, pudiendo añadirse como un submodulo de git.
Si bien este proyecto esta pensado para ser posible su utilización en otros proyectos, aun hay algunas cosas que necesitan ser modificadas para que se adapte a distintos proyectos.
No te olvides de modificar el archivo ./moodle-upgrader/lib/vars.sh para ajustar las variables de acuerdo a tus necesidades.

---

## Install as submodule

```
git submodule add https://recursos.camba.coop/educacion/moodle-upgrader
```  

---

## Estructura del proyecto:
#### /backups/   
Utilizado para guardar backups de los archivos y directorios durante la actualización.

#### /lib/functions.sh
Contiene los métodos utilizados por el programa.

#### /lib/vars.php
Tiene las variables utilizadas por el programa para poder ajustar la ejecución según las necesidades del usuario.

#### /upgrade/
Contiene los dumps (.sql ) de la base de datos que se utilizaran para actualizar.
También contiene el theme (.zip) y la nueva versión de moodle (moodle.tgz)

#### upgrade.sh
Script principal encargado de tomar las opciones y ejecutar el programa de la forma seleccionada.

---

## Estructura del ambiente de desarrollo:

Esta herramienta esta pensada para ser utilizada en conjunto con [*moodle-dev*](https://recursos.camba.coop/educacion/moodle-dev) que es un ambiente de desarrollo para realizar pruebas y actualizaciones en local, utilizando Docker y Docker Compose.

#### /moodle-data-backup/
Contiene el dump de la data de Moodle que hay actualmente en producción, para poder tener en local una copia exacta de producción.

#### /moodle-files/
Contiene los archivos core de moodle.

#### /moodle-upgrader/
El programa en cuestión, encargado de automatizar la actualización.

#### config.php
Contiene la configuración que utilizara Moodle para conectarse a la db y demás.

#### dbPlataforma.php
Dump de la base de datos de producción para poder tener en local una copia exacta de producción.

#### docker-compose.yml
Tiene la receta para levantar los servicios necesarios para ejecutar nuestro Moodle en local.

#### foreground.sh
Ejecuta algunos comandos una vez inicializado el contenedor de moodle. Ajusta los permisos de las carpetas entre otras cosas.

#### moodle_variables.env
Creo que no es necesario ya que se utiliza la data de config.php, se puede borrar.

#### restore.sh
Se encarga de restaurar la base de datos desde el dump.sql

---

## Opciones de ejecución:

### DEBUGGING <small>(-d | --debug)</small>
Habilita el modo debugging, imprimiendo los textos de debug.

### NOUPGRADE <small>(-nu | --no-upgrade)</small>
Saltea la ejecucion del método **perform_upgrade**.

### NOCLEANUP <small>(-nc | --no-cleanup)</small>
Saltea la ejecución del método **cleanup**.

### NOBACKUP <small>(-nb | --no-backup)</small>
Saltea la ejecucion del método **backup_moodle_files**.

### RESTORE_BACKUP <small>(-rb | --restore-backup)</small>
Si se activa esta opción, dentro de la ejecución de **actualizar** en lugar de **backup_moodle_files** se ejecuta **restore_moodle_files**.

### PAUSE <small>(-p | --pause)</small>
Detiene la ejecución del programa entre la ejecución de cada método hasta que el usuario presione una tecla. Util para debugging.

### backup_moodle_files <small>(-bmf | --backup-moodle-files)</small>
Ejecuta solamente el método **backup_moodle_files** y finaliza el programa.

### usage <small>(-h | --help)</small>
Muestra información sobre como utilizar el programa.

### startup_temp <small>(-s | --startup)</small>
Ejecuta solamente el método **startup_temp** y finaliza el programa.

### perform_upgrade  <small>(-u | --upgrade)</small>
Ejecuta solamente el método **perform_upgrade** y finaliza el programa.

### find_missing_plugins <small>(-fmp | --find-missing-plugins)</small>
Ejecuta solamente el método **find_missing_plugins** y finaliza el programa.

### exeCute <small>(--exeCute)</small>
Ejecuta el comando recibido como parámetro. Útil para debugging.

### update_moodle_folder <small>(-umf | --update-moodle-folder)</small>
Ejecuta solamente el método **update_moodle_folder** y finaliza el programa.

### cleanup <small>(-c | --clean)</small>
Ejecuta solamente el método **cleanup** y finaliza el programa.

---

## Métodos

### exeCute:
Ejecuta código recibido como parámetro.

### draw_logo:
Dibuja el logo al comienzo del programa.

### bienvenida:
Muestra un mensaje de bienvenida al ejecutar el programa.

### pause:
Detiene la ejecución del programa hasta que el usuario presione una tecla.

### actualizar
Realiza las siguientes acciones
- detener_contenedores
- startup_temp
- backup_moodle_files
- extract_moodle
- get_eletece_theme
- extract_mb2nl
- extract_plugins
- copy_plugins
- copy_themes
- update_db
- update_moodle_folder
- cleanup
- check_moodle_folder
- start_containers
- find_missing_plugins
- perform_upgrade

### copy_themes
Copia los themes de ./moodle-upgrader/upgrade/theme/* a ./moodle-upgrader/upgrade/temp/moodle/theme/

### detener_contenedores
Ejecuta docker-compose down en el directorio superior para detener los contenedores en ejecución.

### start
Maneja el flujo del programa, realizando las siguientes acciones:
- draw_logo
- bienvenida
- actualizar
- despedir

### startup_temp:
Se encarga de validar que los directorios necesarios existan y crearlos si es necesario.

### restore_moodle_files:
Elimina el directorio ./moodle-files/moodle/ actual y restaura en su lugar el backup ubicado en ./moodle-upgrader/backups/moodle-files.zip

### backup_moodle_files:
Guarda una copia de respaldo del actual directorio ./moodle-files/moodle en ./moodle-upgrader/backups/moodle-files.zip

### extract_moodle:
Extrae la nueva versión de Moodle de ./moodle-upgrader/upgrade/moodle.tgz a la carpeta ./moodle-upgrader/upgrade/temp/

### update_moodle_folder:
Elimina el contenido de la carpeta ./moodle-files/moodle y en su lugar se copia el contenido de la versión actualizada desde ./moodle-upgrader/upgrade/temp/moodle/

### update_db:
Primero se guarda una copia de seguridad de la db desde ./dbPlataforma.sql en el directorio ./moodle-upgrader/backups/dbPlataforma.sql
Luego se le pregunta al usuario que dump debería usar de los disponibles en ./moodle-upgrader/upgrade/*.sql.
Finalmente se copia el dump seleccionado y se lo mueve a ./dbPlataforma.sql para que el docker-compose lo utilice.

### get_eletece_theme:
Se descarga el theme desde el repositorio indicado en la variable LTC_THEME_REPO_URL dentro de ./moodle-upgrader/lib/vars.sh
Se extrae el theme y se mueven los archivos a ./moodle-upgrader/upgrade/theme/eletece

### extract_mb2nl:
Se extrae el theme ./moodle-upgrader/upgrade/mb2nl.zip en la carpeta ./moodle-upgrader/upgrade/temp/mb2nl
Luego se extraen los plugins del theme a ./moodle-upgrader/upgrade/temp/plugins.
Se le pregunta al usuario que versión del theme quiere utilizar dependiendo de la versión de Moodle instalada y se extrae la versión seleccionada en ./moodle-upgrader/upgrade/theme/

### extract_plugins:
Se extraen los plugins de ./moodle-upgrader/upgrade/temp/plugins/ en carpetas según su correspondiente tipo de plugin en ./moodle-upgrader/upgrade/temp/plugins/${category_name}

### copy_plugins:
Se mueven los plgugins de ./moodle-upgrader/upgrade/temp/plugins/ a la correspondiente carpeta en ./moodle-upgrader/upgrade/temp/moodle/

### cleanup:
Se eliminan archivos no necesarios de la carpeta ./moodle-upgrader/upgrade/temp/

### despedir:
Muestra mensaje de despedida antes de cerrar el programa.

### start_containers:
Ejecuta docker-compose up -d en el directorio superior.

### perform_upgrade:
Espera a que Moodle este funcional y ejecuta el cli de Moodle upgrade.php
y purge_caches.php

### check_moodle_folder:
Muestra cual es la versión actual de Moodle luego de la actualización y cuales son los themes instalados.

### usage:
Muestra información sobre las opciones disponibles para ejecutar el programa.

### get_moodle_plugins_list:
Descargamos desde https://download.moodle.org/api/1.3/pluglist.php un json que contiene todos los plugins de moodle, para poder buscar las URLs para descargar los plugins en caso de necesitar actualizar alguno.

### find_missing_plugins:
Compara los plugins encontrados en ./moodle-files/moodle/ contra los de ./moodle-upgrader/upgrade/temp/moodle/ para guardar los plugins faltantes en la variable missing_plugins para luego descargarlos.

### download_missing_plugins:
Busca los plugins faltantes guardados en la variable missing_plugins, buscando la información del plugin en plugins.json y descargándolo desde la web de moodle. Luego se extraen en ./moodle-upgrader/upgrade/temp/plugins
Luego se ejecutan nuevamente las siguientes funciones
- extract_plugins
- copy_plugins
- find_missing_plugins

### escribir:
Escribe a la consola, por lo general se usa para mostrar información sobre que esta haciendo el programa.

### escribir_debug:
Escribe a la consola indicando que se trata de información para debugging.

### escribir_exeCute:
Escribe a la consola el comando que se ejecuta.

### escribir_exeCute_response:
Escribe a la consola la respuesta del comando ejecutado.

### escribir_error:
Escribe a la consola un error de forma especial.

### escribir_header:
Escribe a la consola texto sin ningun tag.
