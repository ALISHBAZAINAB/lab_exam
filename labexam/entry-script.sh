#!/bin/bash
set -e

PUBLIC_IP="3.28.184.87"

yum update -y
yum install -y nginx
systemctl start nginx
systemctl enable nginx

mkdir -p /etc/ssl/private /etc/ssl/certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/selfsigned.key \
  -out /etc/ssl/certs/selfsigned.crt \
  -subj "/CN=${PUBLIC_IP}" \
  -addext "subjectAltName=IP:${PUBLIC_IP}"

cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

cat <<EOF > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
pid /run/nginx.pid;

events { worker_connections 1024; }

http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  upstream backend_servers {
    server 158.252.94.241:80;
    server 158.252.94.242:80 backup;
  }

  server {
    listen 443 ssl;
    server_name ${PUBLIC_IP};

    ssl_certificate /etc/ssl/certs/selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/selfsigned.key;

    location / {
      proxy_pass http://backend_servers;
    }
  }

  server {
    listen 80;
    return 301 https://\$host\$request_uri;
  }
}
EOF

nginx -t
systemctl restart nginx

