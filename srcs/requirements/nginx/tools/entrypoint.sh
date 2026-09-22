#!/bin/sh

if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=TR/ST=Istanbul/L=Istanbul/O=42/OU=42Istanbul/CN=meaydino.42.fr"
fi

exec nginx -g "daemon off;"
