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

    # Admin credentials
    ADMIN_USER="${WP_ADMIN_USER:-meaydino}"
    ADMIN_PASS="$(cat /run/secrets/wp_admin_password 2>/dev/null || tail -n 1 /run/secrets/credentials 2>/dev/null)"
    ADMIN_EMAIL="${WP_ADMIN_EMAIL:-${ADMIN_USER}@student.42.fr}"
    TITLE="${WP_TITLE:-Inception}"

    php -d memory_limit=512M /usr/local/bin/wp core install \
        --path=/var/www/html \
        --url="https://$DOMAIN_NAME" \
        --title="$TITLE" \
        --admin_user="$ADMIN_USER" \
        --admin_password="$ADMIN_PASS" \
        --admin_email="$ADMIN_EMAIL" \
        --allow-root

    php -d memory_limit=512M /usr/local/bin/wp option update comment_moderation 1 \
        --path=/var/www/html \
        --allow-root
    php -d memory_limit=512M /usr/local/bin/wp option update comment_previously_approved 0 \
        --path=/var/www/html \
        --allow-root

    # Normal user (editor) credentials
    USER_NAME="${WP_USER:-wp_editor}"
    USER_PASS="$(cat /run/secrets/wp_user_password 2>/dev/null || tail -n 1 /run/secrets/wp_user_credentials 2>/dev/null)"
    USER_EMAIL="${WP_USER_EMAIL:-${USER_NAME}@student.42.fr}"

    php -d memory_limit=512M /usr/local/bin/wp user create \
        "$USER_NAME" \
        "$USER_EMAIL" \
        --role=editor \
        --user_pass="$USER_PASS" \
        --path=/var/www/html \
        --allow-root
fi

exec php-fpm8.2 -F || exec php-fpm -F
