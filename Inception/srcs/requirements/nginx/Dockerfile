FROM alpine:3.18

RUN apk update && apk add --no-cache nginx openssl

RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/http.d/default.conf

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["entrypoint.sh"]
