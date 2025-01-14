FROM php:8.4.2-fpm-alpine

ARG CONTAINER_PORT
ARG USER_ID
ARG USER_PASSWORD
ARG GROUP_ID
ARG USER_NAME
ARG GROUP_NAME
ARG REDIS_PORT
ARG REDIS_HOST
ARG MYSQL_PORT
ARG MYSQL_HOST

ENV CONTAINER_PORT=${CONTAINER_PORT}
ENV USER_ID=${USER_ID}
ENV USER_PASSWORD=${USER_PASSWORD}
ENV GROUP_ID=${GROUP_ID}
ENV USER_NAME=${USER_NAME}
ENV GROUP_NAME=${GROUP_NAME}
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
RUN sed -i "s/listen = 127.0.0.1:9000/listen = 127.0.0.1:${CONTAINER_PORT}/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/listen = 127.0.0.1:9000/listen = 127.0.0.1:${CONTAINER_PORT}/g" /usr/local/etc/php-fpm.d/www.conf.default
RUN sed -i "s/listen = 9000/listen = ${CONTAINER_PORT}/g" /usr/local/etc/php-fpm.d/zz-docker.conf
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

RUN apk update
RUN apk add --no-cache \
            icu-dev \
            supervisor \
            build-base \
            mysql-client \
            curl \
            gnupg \
            procps \
            unzip \
            gettext \
            libzip-dev \
            libpq-dev

COPY ./start.sh /usr/local/bin/start.sh
COPY ./backup.sh /usr/local/bin/backup.sh
COPY ./php.ini /usr/local/etc/php/

RUN docker-php-ext-configure intl
RUN docker-php-ext-configure pcntl --enable-pcntl
RUN docker-php-ext-install zip mysqli pdo pdo_mysql intl pcntl

RUN mkdir -p /etc/supervisor/logs
RUN mkdir -p /var/www/html/storage/logs/
RUN chmod +x /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/backup.sh

WORKDIR /var/www/html/

ENTRYPOINT ["/usr/local/bin/start.sh"]

EXPOSE ${CONTAINER_PORT}
