#!/bin/sh

cd /var/www/html

php_host=${PHP_HOST:-app}
redis_host=${REDIS_HOST:-redis}
redis_port=${REDIS_PORT:-6373}
mysql_host=${MYSQL_HOST:-mysql}
mysql_port=${MYSQL_PORT:-3306}

if [ ! -d /var/www/html/vendor ]; then
    composer install
fi

if [ ! -d /var/www/html/vendor/laravel ]; then
  echo "Laravel installation..."
  composer create-project laravel/laravel /var/www/html/tmp/

  if [ -f /var/www/html/.gitignore ] && [ -f /var/www/html/tmp/.gitignore ]; then
    cat /var/www/html/tmp/.gitignore >> /var/www/html/.gitignore
    sort /var/www/html/.gitignore | uniq > /var/www/html/.tmp.txt
    mv /var/www/html/.tmp.txt /var/www/html/.gitignore
    rm /var/www/html/tmp/.gitignore
  fi

  mv /var/www/html/tmp/* /var/www/html/
  mv /var/www/html/tmp/.editorconfig /var/www/html/ 2>/dev/null
  mv /var/www/html/tmp/.env /var/www/html/ 2>/dev/null
  mv /var/www/html/tmp/.env.example /var/www/html/ 2>/dev/null
  mv /var/www/html/tmp/.gitattributes /var/www/html/ 2>/dev/null
  rm -r /var/www/html/tmp/
fi

if [ ! -d /var/www/html/vendor/predis ]; then
    composer require predis/predis
fi

if [ ! -d /var/www/html/vendor/laravel/horizon ]; then
    composer require laravel/horizon
    php artisan horizon:install
fi

if [ ! -d /var/www/html/vendor/laravel/telescope ]; then
    composer require laravel/telescope --dev
    php artisan telescope:install
fi

if [ ! -d /var/www/html/node_modules ]; then
    npm install
fi

if [ ! -d /var/www/html/node_modules/prettier ]; then
    npm install --save-dev prettier
fi

if [ ! -f /var/www/html/.env ]; then
    cp .env.example .env;
    php artisan key:generate;
fi

if [ ! -d /var/www/html/.husky ]; then
    npm install husky --save-dev
    npx husky init
    rm /var/www/html/.husky/pre-commit
fi

if [ ! -f /var/www/html/.husky/pre-commit ]; then
    echo "#!/bin/sh" > /var/www/html/.husky/pre-commit
    echo "docker exec $php_host composer pint" >> /var/www/html/.husky/pre-commit
    echo "docker exec $php_host npm run prettier" >> /var/www/html/.husky/pre-commit
    chmod +x /var/www/html/.husky/pre-commit
fi

while ! nc -z $redis_host $redis_port; do
  echo "Waiting for $redis_host:$redis_port to be available..."
  sleep 2
done

while ! nc -z $mysql_host $mysql_port; do
  echo "Waiting for $mysql_host:$mysql_port to be available..."
  sleep 2
done

# Перевірка на наявність міграцій
checkMigrations=$(php artisan db:table migrations 2>&1)
if echo $checkMigrations | grep -q "WARN Table \[migrations\]"; then
    php artisan migrate:fresh --seed;
    echo "Executed migrations..."
fi

echo "Clear caching configuration..."
php artisan queue:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

npm run build

php-fpm
