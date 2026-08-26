FROM alpine:3.18

RUN apk update && apk add --no-cache \
    php \
    php-fpm \
    php-mysqli \
    php-mbstring \
    php-json \
    php-session \
    php-curl \
    php-gd \
    php-xml \
    php-intl \
    php-zip \
    php-phar \
    wget \
    mariadb-client \
    unzip

# PHP-FPM konfigürasyonunu 9000 portunu dinleyecek ve genel bağlantıya izin verecek şekilde ayarla
RUN sed -i "s|listen = 127.0.0.1:9000|listen = 0.0.0.0:9000|g" /etc/php81/php-fpm.d/www.conf || \
    sed -i "s|listen = 127.0.0.1:9000|listen = 0.0.0.0:9000|g" /etc/php82/php-fpm.d/www.conf || \
    sed -i "s|listen = 127.0.0.1:9000|listen = 0.0.0.0:9000|g" /etc/php8/php-fpm.d/www.conf || \
    sed -i "s|listen = /([^/]*)/([[:alnum:]]*).sock|listen = 0.0.0.0:9000|g" /etc/php81/php-fpm.d/www.conf || true

# WP-CLI (WordPress Komut Satırı Aracı) indirme
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

WORKDIR /var/www/html

# Başlangıç betiğini kopyala
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
