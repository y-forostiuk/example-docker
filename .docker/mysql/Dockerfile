FROM mysql:8.0.40-debian

COPY ./mysql.cnf /etc/mysql/conf.d/my.cnf
RUN chmod 644 /etc/mysql/conf.d/my.cnf

RUN apt-get update && rm -rf /var/lib/apt/lists/*

# Створення папок для логів MySQL
RUN mkdir -p /var/log/mysql \
    && touch /var/log/mysql/mysql-error.log \
    /var/log/mysql/mysql-slow.log \
    /var/log/mysql/mysql-query.log \
    /var/log/mysql/mysql-bin.log \
    && chown -R mysql:mysql /var/log/mysql

# Запуск MySQL
CMD tail -f /var/log/mysql/mysql-error.log & exec docker-entrypoint.sh mysqld

