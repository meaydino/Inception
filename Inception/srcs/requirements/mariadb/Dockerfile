FROM alpine:3.18

RUN apk update && apk add --no-cache mariadb mariadb-client

# MariaDB çalışma dizini ve yetkiler
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

# MariaDB yapılandırma dosyasını kopyala
COPY conf/mariadb.cnf /etc/my.cnf.d/mariadb.cnf

# Başlangıç betiğini kopyala
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["entrypoint.sh"]
