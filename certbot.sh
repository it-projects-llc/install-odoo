#!/bin/bash
echo 'deb http://ftp.debian.org/debian jessie-backports main' | sudo tee /etc/apt/sources.list.d/backports.list
apt-get update
apt-get install certbot -t jessie-backports -y
certbot certonly -d {{ODOO_DOMAIN}}
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
