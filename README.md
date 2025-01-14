# Docker for Laravel project (or vanilla PHP)

Що є в цьому docker-compose.yml:

- Database. Використовується MySQL v8.0.40
- Redis v7.4.2, Alpine версія
- PHPMyAdmin v5.2.1, через проксування Nginx
- PHP v8.4.2, FPM-Alpine версія
- Nginx v1.27.3, Alpine версія
- MailPit v1.21.8
- Supervisor, винесений в окремий контейнер з PHP v8.4.2-fpm-alpine
- Schedule, винесений в окремий контейнер з PHP v8.4.2-fpm-alpine

## Детальний опис "фіч" контейнерів

* Nginx:
  * Всі порти для налаштування nginx підставляються автоматично
  * При запуску контейнеру генерується самопідписаний SSL-сертифікат
  * Перехід на PHPMyAdmin відбувається через запит до основного порта проекту та шлях /phpmyadmin/, приклад: __https://localhost:8080/phpmyadmin/__
  * Запити на NodeJS та Vite (для Laravel) переправляються через обробку шляху __/(vite|node_modules)/__
* Supervisor:
  * При запуску також стартує CRON на збереження бази даних в *./.docker/backup/[backup-name].sql.qz* який буде зберігати бекапи за останні 3 дні, 3 тижні та 3 місяці
  * При запуску внутрішнього скрипта *./.docker/daemons/start.sh* буде перевірятися чи запустились контейнери з Redis та MySQL, та ставити виконання на паузу поки ці контейнери не запущені
* Supervisor та Schedule:
  * При запуску внутрішнього скрипта *./.docker/daemons/start.sh* буде перевірятися чи створена таблиця міграцій, і в разі відсутності скрипт буде на паузі та очікувати створення міграцій
* PHP:
  * При запуску внутрішнього скрипта *./.docker/php/scripts.sh* буде перевірятися чи запустились контейнери з Redis та MySQL, та ставити виконання на паузу поки ці контейнери не запущені
  * При запуску внутрішнього скрипта *./.docker/php/scripts.sh* буде перевірятися наявність міграцій в базі даних та в разі відсутності запуститься команда:
    ```bash
    php artisan migration:fresh --seed
    ```

## Запуск

Для запуску потрібно буде використовувати прописаний *.env.docker* наступними командами:
```bash
docker compose --env-file='./env.docker' build # Для збірки всього проекту
docker compose --env-file='./env.docker' up -d # Для запуску проекту
docker compose --env-file='./env.docker' down # Для зупинки проекту 
```

## Запуск без розгортання Laravel

Для уникнення проблем та помилок раджу зробити наступне:

* В *docker-compose.yml* видалити контейнер що відповідає за __schedule__
* В *.docker/daemons/supervisord.conf.template* видалити наступні програми: __program:queue_redis__, __program:horizon__
* В *.docker/nginx/default.conf.template* змінити направлення запитів з __root /var/www/html/public/;__ на потрібний для вас шлях
* В *.docker/php/scripts.sh* видалити наступні конструкції if:
```bash
# З 15 по 32 рядок
if [ ! -d /var/www/html/vendor/laravel ]; then
  echo "Laravel installation..."
  # Та інший код в цьому блоці
fi
```
```bash
if [ ! -d /var/www/html/vendor/laravel/horizon ]; then
    composer require laravel/horizon
    php artisan horizon:install
fi
```
```bash
if [ ! -d /var/www/html/vendor/laravel/telescope ]; then
    composer require laravel/telescope --dev
    php artisan telescope:install
fi
```
```bash
if [ ! -f /var/www/html/.env ]; then
    cp .env.example .env;
    php artisan key:generate;
fi
```
```bash
# Перевірка на наявність міграцій
checkMigrations=$(php artisan db:table migrations 2>&1)
if echo $checkMigrations | grep -q "WARN Table \[migrations\]"; then
    php artisan migrate:fresh --seed;
    echo "Executed migrations..."
fi
```
```bash
echo "Clear caching configuration..."
php artisan queue:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
```
* В *.docker/daemons/start.sh* видалити наступні конструкції:
```bash
checkMigrations=$(php artisan db:table migrations 2>&1)
while echo $checkMigrations | grep -q "WARN Table \[migrations\]"; do
    echo "Увага: 'Table [migrations]' не існує. Зачекаємо, поки не буде створено..."
    sleep 5
    checkMigrations=$(php artisan db:table migrations 2>&1)
done
```
```bash
# Також потрібно буде видалити частину скрипта яка запускає Scheduler
elif [ "$role" = "scheduler" ]; then
    while [ true ]
    do
        exec su - $uname -c "php /var/www/html/artisan schedule:run --verbose --no-interaction & sleep 60"
    done
```
* Потрібно буде прописати встановлення якогось пакету для форматування PHP коду та налаштувати його виклик замість наступного рядку в *.docker/php/scripts.sh*:
```bash
echo "docker exec $php_host composer pint" >> /var/www/html/.husky/pre-commit
# Використання вашого пакету, наприклад PHP_CodeSniffer
echo "docker exec $php_host composer phpcbf" >> /var/www/html/.husky/pre-commit
```
* Змінити шлях публікації логів з */storage/logs/[name].log* на потрібний вам

## Зміна портів Docker контейнерів

Для зміни всіх портів що використовуються контейнерами потрібно буде відредагувати файл *.env.docker*, де є опції налаштування всіх портів, вони мають в кінці назви "___PORT__"

## Ліцензія

[MIT](https://choosealicense.com/licenses/mit/)
