FROM nginx:latest

# Configuration
COPY default.conf /etc/nginx/conf.d/

# SSL key/cert
RUN mkdir -p /etc/nginx/ssl/www_ibgib_com
COPY www_ibgib_com.crt /etc/nginx/ssl/www_ibgib_com/
COPY www_ibgib_com.key /etc/nginx/ssl/www_ibgib_com/

# Ports
EXPOSE 80 443
