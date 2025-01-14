FROM php:8.4.2-fpm-alpine

ARG USER_ID
ARG GROUP_ID
ARG USER_NAME
ARG GROUP_NAME
ARG PHP_PORT
ARG PHP_HOST
ARG REDIS_PORT
ARG REDIS_HOST
ARG MYSQL_PORT
ARG MYSQL_HOST

ENV USER_ID=${USER_ID}
ENV GROUP_ID=${GROUP_ID}
ENV USER_NAME=${USER_NAME}
ENV GROUP_NAME=${GROUP_NAME}
ENV PHP_HOST=${PHP_HOST}
ENV PHP_PORT=${PHP_PORT}
ENV REDIS_PORT=${REDIS_PORT}
ENV REDIS_HOST=${REDIS_HOST}
ENV MYSQL_PORT=${MYSQL_PORT}
ENV MYSQL_HOST=${MYSQL_HOST}

USER root

RUN mkdir -p /var/www/html
WORKDIR /var/www/html/

RUN addgroup -g ${GROUP_ID} --system ${GROUP_NAME}
RUN adduser -G ${GROUP_NAME} --system -D --shell /bin/sh -u ${USER_ID} ${USER_NAME}

RUN sed -i "s/user = www-data/user = ${USER_NAME}/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/group = www-data/group = ${GROUP_NAME}/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/listen = 127.0.0.1:9000/listen = 127.0.0.1:${PHP_PORT}/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/listen = 127.0.0.1:9000/listen = 127.0.0.1:${PHP_PORT}/g" /usr/local/etc/php-fpm.d/www.conf.default
RUN sed -i "s/listen = 9000/listen = ${PHP_PORT}/g" /usr/local/etc/php-fpm.d/zz-docker.conf
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

RUN apk update
RUN apk add --no-cache \
    build-base \
    zlib-dev \
    curl \
    gnupg \
    procps \
    zip \
    unzip \
    mysql-client \
    mysql-dev \
    oniguruma-dev \
    libxml2-dev \
    icu-dev \
    bzip2-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    freetype-dev \
    libzip-dev \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    autoconf \
    gettext \
    nodejs \
    npm

RUN docker-php-ext-configure intl
RUN docker-php-ext-configure pcntl --enable-pcntl
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install zip mysqli pdo pdo_mysql intl gd pcntl
RUN pecl install pcov && docker-php-ext-enable pcov
RUN rm -rf /var/cache/apk/*

# Xdebug
# RUN pecl install xdebug \
# && docker-php-ext-enable xdebug \
# && echo ";zend_extension=xdebug" > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

## Node.js, NPM, Yarn
RUN apk add --no-cache nodejs-current npm
RUN npm install npm@latest -g

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer config --global process-timeout 3600

COPY ./scripts.sh /usr/local/bin/scripts.sh
COPY ./php.ini /usr/local/etc/php/
RUN chmod +x /usr/local/bin/scripts.sh

# Assign permissions of the working directory
RUN chmod -R 777 .
RUN chown -R ${USER_NAME}:${GROUP_NAME} .

USER ${USER_NAME}

ENTRYPOINT ["/usr/local/bin/scripts.sh"]

EXPOSE ${PHP_PORT}


