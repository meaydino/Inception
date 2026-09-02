#!/bin/sh

if [ ! -d "/var/lib/mysql/mysql" ]; then
    chown -R mysql:mysql /var/lib/mysql

    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;

ALTER USER 'root'@'localhost' IDENTIFIED BY '$(cat /run/secrets/db_root_password)';
CREATE USER 'root'@'%' IDENTIFIED BY '$(cat /run/secrets/db_root_password)';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '$(cat /run/secrets/db_password)';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF
fi

exec mysqld --user=mysql
