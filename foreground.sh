#!/bin/bash

echo "placeholder" > /var/moodledata/placeholder
git clone -b MOODLE_311_STABLE git://git.moodle.org/moodle.git --depth=1 /var/www/html/
chown -R www-data:www-data /var/www/html
chown -R www-data:www-data /var/moodledata
chmod 777 /var/moodledata
chmod 777 /var/www/html

read pid cmd state ppid pgrp session tty_nr tpgid rest < /proc/self/stat
trap "kill -TERM -$pgrp; exit" EXIT TERM KILL SIGKILL SIGTERM SIGQUIT

#start up cron
/usr/sbin/cron


source /etc/apache2/envvars
tail -F /var/log/apache2/* &
exec apache2 -D FOREGROUND
