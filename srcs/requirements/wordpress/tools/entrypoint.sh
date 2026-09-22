#!/bin/sh

if [ ! -f /var/www/html/wp-config.php ]; then
    chown -R www-data:www-data /var/www/html 2>/dev/null || true
    chmod -R 755 /var/www/html

    if [ ! -f /var/www/html/wp-includes/version.php ]; then
        php -d memory_limit=512M /usr/local/bin/wp core download --path=/var/www/html --allow-root
    fi

    until mariadb-admin ping \
        -h"mariadb" \
        -u"$MYSQL_USER" \
        -p"$(cat /run/secrets/db_password)" \
        --silent; do
        sleep 1
    done

    php -d memory_limit=512M /usr/local/bin/wp config create \
        --path=/var/www/html \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$(cat /run/secrets/db_password)" \
        --dbhost="mariadb:3306" \
        --allow-root

    php -d memory_limit=512M /usr/local/bin/wp core install \
        --path=/var/www/html \
        --url="https://$DOMAIN_NAME" \
        --title="Inception" \
        --admin_user="$(cat /run/secrets/credentials | head -n 1)" \
        --admin_password="$(cat /run/secrets/credentials | tail -n 1)" \
        --admin_email="meaydino@student.42.fr" \
        --allow-root

    php -d memory_limit=512M /usr/local/bin/wp option update comment_moderation 1 \
        --path=/var/www/html \
        --allow-root
    php -d memory_limit=512M /usr/local/bin/wp option update comment_previously_approved 0 \
        --path=/var/www/html \
        --allow-root

    WP_USER="$(cat /run/secrets/wp_user_credentials | head -n 1)"
    WP_PASS="$(cat /run/secrets/wp_user_credentials | tail -n 1)"
    php -d memory_limit=512M /usr/local/bin/wp user create \
        "$WP_USER" \
        "${WP_USER}@student.42.fr" \
        --role=editor \
        --user_pass="$WP_PASS" \
        --path=/var/www/html \
        --allow-root
fi

exec php-fpm8.2 -F || exec php-fpm -F
