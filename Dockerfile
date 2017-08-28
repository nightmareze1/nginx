FROM nginx
MAINTAINER: Ezequiel
COPY site /usr/share/nginx/html
EXPOSE 80 443
