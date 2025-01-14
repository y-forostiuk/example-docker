#!/bin/sh

role=${CONTAINER_ROLE:-none}
uname=${USER_NAME:-user}
gname=${GROUP_NAME:-group}
redis_host=${REDIS_HOST:-redis}
redis_port=${REDIS_PORT:-6373}
mysql_host=${MYSQL_HOST:-mysql}
mysql_port=${MYSQL_PORT:-3306}

chmod -R 0775 .
chown -R "$uname":"$gname" /var/www/html

while ! nc -z $redis_host $redis_port; do
  echo "Waiting for $redis_host:$redis_port to be available..."
  sleep 2
done

while ! nc -z $mysql_host $mysql_port; do
  echo "Waiting for $mysql_host:$mysql_port to be available..."
  sleep 2
done

checkMigrations=$(php artisan db:table migrations 2>&1)
while echo $checkMigrations | grep -q "WARN Table \[migrations\]"; do
    echo "Увага: 'Table [migrations]' не існує. Зачекаємо, поки не буде створено..."
    sleep 5
    checkMigrations=$(php artisan db:table migrations 2>&1)
done

if [ -d /var/www/html/vendor/laravel ]; then
    if [ "$role" = "supervisor" ]; then
        envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < /var/www/html/.docker/daemons/supervisord.conf.template > /etc/supervisor/supervisord.conf
        envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < /var/www/html/.docker/daemons/crontab.template > /var/spool/cron/database
        chown $uname:$gname /var/spool/cron/database
        chmod 0644 /var/spool/cron/database
        crontab -u $uname /var/spool/cron/database
        crontab /var/spool/cron/database

        exec supervisord --configuration /etc/supervisor/supervisord.conf
    elif [ "$role" = "scheduler" ]; then
        while [ true ]
        do
            exec su - $uname -c "php /var/www/html/artisan schedule:run --verbose --no-interaction & sleep 60"
        done
    else
        echo "Could not match the container role \"$role\""
        exit 1
    fi
fi

exec "$@"
