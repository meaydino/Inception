FROM alpine:3.18

RUN apk update && apk add --no-cache nginx openssl

# SSL sertifikaları için klasör
RUN mkdir -p /etc/nginx/ssl

# NGINX konfigürasyonunu kopyala
COPY conf/nginx.conf /etc/nginx/http.d/default.conf

# SSL sertifikası üretecek betik
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["entrypoint.sh"]
