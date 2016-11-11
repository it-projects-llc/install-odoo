#!/bin/bash -x

set -e

# set odoo database host, port, user and password
# try to use linked DB first and if it's empty use RDS values
: ${PGHOST:=${DB_PORT_5432_TCP_ADDR:=$RDS_HOSTNAME}}
: ${PGPORT:=${DB_PORT_5432_TCP_PORT:=$RDS_PORT}}
: ${PGUSER:=${DB_ENV_POSTGRES_USER:=${RDS_USERNAME:='postgres'}}}
: ${PGPASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=$RDS_PASSWORD}}
export PGHOST PGPORT PGUSER PGPASSWORD

case "$1" in
	  --)
		    shift
		    exec /mnt/odoo-source/odoo-bin "$@"
		    ;;
	  -*)
		    exec /mnt/odoo-source/odoo-bin "$@"
		    ;;
	  *)
		    exec "$@"
esac

exit 1
