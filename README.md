# install-odoo

Install developement or production 
[odoo](https://www.odoo.com/) from [git](https://github.com/odoo/odoo)
with or without using [docker](https://www.docker.com/), 
with or without using [Amazon RDS](https://aws.amazon.com/rds/), with additional improvements: 

* Attachments are stored in postgres large objects by default
* Completely debranded system
* Save sessions to postgres. It simplifies multi-instance deployment

# Basic usage

## Getting script

    apt-get update | grep "Hit http\|Ign http" -C 10000 && echo "There are possible failures on fetching. Try apt-get update again"
    
    apt-get install git -y
    git clone https://github.com/it-projects-llc/install-odoo.git
    cd install-odoo
    
## Running script

    # run script with parameters you need
    # (list of all parameters with default values can be found at install-odoo-saas.sh)
    INSTALL_DEPENDENCIES=yes \
    INIT_POSTGRESQL=yes \
    INIT_BACKUPS=yes \
    INIT_NGINX=yes \
    INIT_START_SCRIPTS=yes \
    INIT_ODOO_CONFIG=yes \
    INIT_USER=yes \
    INIT_DIRS=yes \
    CLONE_ODOO=yes \
    CLONE_IT_PROJECTS_LLC=yes \
    CLONE_OCA=yes \
    UPDATE_ADDONS_PATH=yes \
    ADD_AUTOINSTALL_MODULES="['ir_attachment_force_storage']"
    /bin/bash -x install-odoo-saas.sh

## After installation

    # show settings (admin password, addons path)
    head /etc/openerp-server.conf
    # show odoo version
    grep '^version_info ' $ODOO_SOURCE_DIR/openerp/release.py

    # PGTune: http://pgtune.leopard.in.ua/"

    # log
    tail -f -n 100 /var/log/odoo/odoo-server.log
    
    # start from console (for ODOO_USER=odoo):
    sudo su - odoo -s /bin/bash -c  "/usr/local/src/odoo-source/odoo-bin -c /etc/openerp-server.conf"
    
    # psql (use name of your database)
    sudo -u odoo psql DATABASE
    
    # some common issues:
    # https://www.odoo.com/forum/help-1/question/dataerror-new-encoding-utf8-is-incompatible-with-the-encoding-of-the-template-database-sql-ascii-52124



# Installation in Docker

## Install Docker engine

    # Install docker
    # see https://docs.docker.com/engine/installation/
    apt-get install -y apt-transport-https ca-certificates
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

    # Ubuntu 12.04
    echo "deb https://apt.dockerproject.org/repo ubuntu-precise main" > /etc/apt/sources.list.d/docker.list

    # Ubuntu 14.04
    echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list

    # Ubuntu 16.04
    echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list

    apt-get update

    apt-get install -y linux-image-extra-$(uname -r)

    apt-get install -y docker-engine

## Create postgres container 

    # create postgres container
    docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db-odoo postgres:9.5

## Create odoo container

Simplest way to create odoo container is as following:

    # run (create) container
    docker run \
    -p 8069:8069 \
    -p 8072:8072 \
    --name odoo \
    --link db-odoo:db \
    -t itprojectsllc/install-odoo

Additionally, you can specify following environment variables:

* ``-e ODOO_MASTER_PASS=123abcd`` -- specify master password (one, you will use on Database Manager page). If this variable is not specified, system will generate new password on each start.
* ``-e RESET_ADMIN_PASSWORDS_ON_STARTUP=yes`` -- will reset admin password at all databases to ``$ODOO_MASTER_PASS`` (manual or generated value)

For more specific installation check following links:

* [Docker for development](docs/dev.rst)
* [SaaS dockers](docs/saas.rst)
* [Odoo versions](docs/odoo-versions.rst)


Finish docker installation:

    # start
    docker start odoo

    # update source
    docker exec GIT_PULL=yes /bin/bash /install-odoo-saas.sh

    # restart
    docker restart odoo

    # prepare nginx (apache will be removed if installed)
    INIT_NGINX=yes \
    install-odoo-saas.sh

    # add start scripts
    INIT_START_SCRIPTS=docker-host \
    install-odoo-saas.sh

# SaaS Tools

To prepare [saas tools](https://github.com/it-projects-llc/odoo-saas-tools) do as on examples below.

Example for base installation

    INIT_SAAS_TOOLS_VALUE="\
    --portal-create \
    --server-create \
    --plan-create \
    --odoo-script=/usr/local/src/odoo-source/odoo-bin \
    --odoo-config=/etc/openerp-server.conf \
    --admin-password='${ODOO_MASTER_PASS}' \
    --portal-db-name=${ODOO_DOMAIN} \
    --server-db-name=server-1.${ODOO_DOMAIN} \
    --plan-template-db-name=template-1.${ODOO_DOMAIN} \
    --plan-clients=demo-%i.${ODOO_DOMAIN} \
    --odoo-xmlrpc-port=8069 \
    "
    INIT_SAAS_TOOLS=$INIT_SAAS_TOOLS_VALUE bash -x install-odoo-saas.sh

Example for docker installation

    INIT_SAAS_TOOLS_VALUE="\
    --portal-create \
    --server-create \
    --plan-create \
    --odoo-script=/mnt/odoo-source/odoo-bin \
    --odoo-config=/mnt/config/odoo-server.conf \
    --admin-password='${ODOO_MASTER_PASS}' \
    --portal-db-name=${ODOO_DOMAIN} \
    --server-db-name=server-1.${ODOO_DOMAIN} \
    --plan-template-db-name=template-1.${ODOO_DOMAIN} \
    --plan-clients=demo-%i.${ODOO_DOMAIN} \
    --odoo-xmlrpc-port=8869 \
    "

    docker exec -u root -i -t odoo /bin/bash -c "export INIT_SAAS_TOOLS='$INIT_SAAS_TOOLS_VALUE'; bash /install-odoo-saas.sh"
    
After that you need to edit config file and update db_filter value to *^%h$*.

# Contributors

* [@yelizariev](https://github.com/yelizariev) - original semi-automated [script](https://gist.github.com/yelizariev/2abdd91d00dddc4e4fa4) for odoo installation
* [@bassn](https://github.com/bassn) - fully auto-automated [script](https://gist.github.com/bassn/996f8b168f0b1406dd54) for odoo installation
