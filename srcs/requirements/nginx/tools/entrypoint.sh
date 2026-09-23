#!/bin/sh

if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=TR/ST=Kocaeli/L=Gebze/O=42/OU=42Kocaeli/CN=meaydino.42.fr"
fi

exec nginx -g "daemon off;"
