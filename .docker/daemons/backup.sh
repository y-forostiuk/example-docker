#!/bin/sh

echo "Backup запущено: $(date)" >> /var/www/html/storage/logs/cron.log 2>&1

# Перевірка типу бекапу
if [ -z "$1" ]; then
  echo "Тип бекапу не вказаний. Використовуйте daily, weekly або monthly."
  exit 1
fi

# Зміни змінні для підключення до бази даних
DB_NAME=${MYSQL_DATABASE:-database}
DB_USER=${MYSQL_USER:-user}
DB_PASSWORD=${MYSQL_PASSWORD:-password}
DB_HOST=${MYSQL_HOST:-db}
DB_PORT=${MYSQL_PORT:-3306}
BACKUP_DIR="/var/www/html/.docker/backup"
DATE=$(date +%Y-%m-%d)

echo $DB_NAME
echo $DB_USER
echo $DB_PASSWORD
echo $DB_HOST
echo $DB_PORT

mkdir -p $BACKUP_DIR

# Визначення директорії для зберігання бекапу
case $1 in
  daily)
    BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$1-$DATE.sql.gz"
    OVERDUE_DAYS="3"
    ;;
  weekly)
    BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$1-$DATE.sql.gz"
    OVERDUE_DAYS="21"
    ;;
  monthly)
    BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$1-$DATE.sql.gz"
    OVERDUE_DAYS="90"
    ;;
  *)
    echo "Невідомий тип бекапу: $1. Використовуйте daily, weekly або monthly."
    exit 1
    ;;
esac

# Створення бекапу
mariadb-dump --skip-ssl \
  --skip-ssl-verify-server-cert \
  --no-tablespaces \
  --host="${DB_HOST}" \
  --port="${DB_PORT}" \
  --user="${DB_USER}" \
  --password="${DB_PASSWORD}" \
  "${DB_NAME}" | gzip -c > "$BACKUP_FILE"

find $BACKUP_DIR -type f -name "$DB_NAME-$1-*.sql.gz" -mtime +$OVERDUE_DAYS -exec rm -f {} \;

# Перевірка успішності бекапу
if [ $? -eq 0 ]; then
  echo "Бекап $1, за $DATE, створений успішно."
else
  echo "Помилка під час створення бекапу $1 за $DATE"
  exit 1
fi
