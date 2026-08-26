#!/bin/sh

# Eğer WordPress daha önce indirilmediyse indir
if [ ! -f /var/www/html/wp-config.php ]; then
    # Dosya izinlerini ayarla
    chown -R www-data:www-data /var/www/html 2>/dev/null || true
    chmod -R 755 /var/www/html

    # Bellek limitini artırarak WordPress'i indir
    php -d memory_limit=512M /usr/local/bin/wp core download --path=/var/www/html --allow-root

    # Veritabanı bağlantı ayarlarını yap
    php -d memory_limit=512M /usr/local/bin/wp config create \
        --path=/var/www/html \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$(cat /run/secrets/db_password)" \
        --dbhost="mariadb:3306" \
        --allow-root

    # WordPress kurulumunu tamamla (admin kullanıcısını oluştur)
    php -d memory_limit=512M /usr/local/bin/wp core install \
        --path=/var/www/html \
        --url="https://$DOMAIN_NAME" \
        --title="Inception" \
        --admin_user="$(cat /run/secrets/credentials | head -n 1)" \
        --admin_password="$(cat /run/secrets/credentials | tail -n 1)" \
        --admin_email="meaydino@student.42.fr" \
        --allow-root

    # İkinci kullanıcıyı oluştur (editor rolü — admin değil)
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

# PHP-FPM'i ön planda (foreground) çalıştır
exec php-fpm81 -F || exec php-fpm82 -F || exec php-fpm -F
