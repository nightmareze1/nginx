FROM nginx
COPY site /usr/share/nginx/html/api/helloprim-ms
COPY helloprim /etc/nginx/conf.d/default.conf

EXPOSE 80 443
