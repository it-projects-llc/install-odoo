#!/bin/bash

# override init file
echo 'source /start.sh' > /opt/odoo/.profile

# copy environment to ssh environment
echo "export DB_PORT_5432_TCP_ADDR=$DB_PORT_5432_TCP_ADDR"       >> /opt/odoo/.profile
echo "export DB_PORT_5432_TCP_PORT=$DB_PORT_5432_TCP_PORT"       >> /opt/odoo/.profile
echo "export DB_ENV_POSTGRES_USER=$DB_ENV_POSTGRES_USER"         >> /opt/odoo/.profile
echo "export DB_ENV_POSTGRES_PASSWORD=$DB_ENV_POSTGRES_PASSWORD" >> /opt/odoo/.profile

/usr/sbin/sshd -D
