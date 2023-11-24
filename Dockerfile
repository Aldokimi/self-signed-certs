FROM nginx:latest

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY www/index.html /usr/share/nginx/html/index.html
