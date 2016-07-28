# install-odoo

Install developement / production [odoo](https://www.odoo.com/) from [git](https://github.com/odoo/odoo) with / without using [docker](https://www.docker.com/).

## Basic usage

    apt-get install git -y
    git clone https://github.com/it-projects-llc/install-odoo.git
    cd install-odoo

    # run script with parameters you need
    # (list of all parameters with default values can be found at install-odoo-saas.sh)
    INSTALL_DEPENDENCIES=yes \
    INIT_POSTGRESQL=yes \
    INIT_BACKUPS=yes \
    INIT_NGINX=yes \
    INIT_START_SCRIPTS=yes \
    INIT_ODOO_CONFIG=yes \
    INIT_DIRS=yes \
    CLONE_ODOO=yes \
    CLONE_IT_PROJECTS_LLC=yes \
    CLONE_OCA=yes \
    UPDATE_ADDONS_PATH=yes \
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
    sudo su - odoo -s /bin/bash -c  "/usr/local/src/odoo-source/openerp-server -c /etc/openerp-server.conf"
    
    # psql (use name of your database)
    sudo -u odoo psql DATABASE
    
    # some common issues:
    # https://www.odoo.com/forum/help-1/question/dataerror-new-encoding-utf8-is-incompatible-with-the-encoding-of-the-template-database-sql-ascii-52124



## Install in Docker

    # Install docker
    # see https://docs.docker.com/engine/installation/
    apt-get install -y apt-transport-https ca-certificates
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

    # Ubuntu 12.04
    echo "deb https://apt.dockerproject.org/repo ubuntu-precise main" > /etc/apt/sources.list.d/docker.list

    # Ubunto 14.04
    echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list

    apt-get update

    apt-get install -y linux-image-extra-$(uname -r)

    apt-get install -y docker-engine


    # build image
    cd /path/to/install-odoo/
    docker build -t install-odoo-dev .


    mkdir odoo
    cd odoo
    BASE_DIR=`pwd`
    mkdir odoo-source
    mkdir extra-addons
    mkdir config
    mkdir data-dir
    mkdir logs
    
    # clone odoo and extra-addons, prepare openerp config file
    ODOO_DIR=${BASE_DIR}/odoo-source \
    ADDONS_DIR=${BASE_DIR}/extra-addons \
    CLONE_ODOO=yes \
    CLONE_IT_PROJECTS_LLC=yes \
    CLONE_OCA=yes \
    CLONE_SAAS=yes \
    OPENERP_SERVER=${BASE_DIR}/config/openerp-server.conf \
    INIT_ODOO_CONFIG=yes \
    install-odoo-saas.sh

    # run (create) postgres container
    docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db-odoo postgres:9.5

    # run (create) container
    docker run \
    -v ${BASE_DIR}/odoo-source/:/mnt/odoo-source/ \
    -v ${BASE_DIR}/extra-addons/:/mnt/extra-addons/ \
    -v ${BASE_DIR}/odoo-config/:/mnt/config/ \
    -v ${BASE_DIR}/data-dir/:/mnt/data-dir/ \
    -v ${BASE_DIR}/logs/:/mnt/logs/ \
    -p 8069:8069 \
    --name odoo \
    --link db-odoo:db

    # run your docker
    docker start odoo

    # update addons_path
    docker exec UPDATE_ADDONS_PATH=yes /bin/bash /install-odoo-saas.sh

    # restart
    docker restart odoo

    # prepare nginx (apache will be removed if installed)
    INIT_NGINX=yes \
    install-odoo-saas.sh

    # add start scripts
    INIT_START_SCRIPTS=docker-host \
    install-odoo-saas.sh

## SaaS Tools

To prepare [saas tools](https://github.com/it-projects-llc/odoo-saas-tools) specify params for ``saas.py`` script, e.g.:

    INIT_SAAS_TOOLS_VALUE="\
    --portal-create \
    --server-create \
    --plan-create \
    --odoo-script=/usr/local/src/odoo-source/openerp-server \
    --odoo-config=/etc/openerp-server.conf \
    --admin-password=${ODOO_MASTER_PASS} \
    --portal-db-name=${ODOO_DOMAIN} \
    --server-db-name=server-1.${ODOO_DOMAIN} \
    --plan-template-db-name=template-1.${ODOO_DOMAIN} \
    --plan-clients=demo-%i.${ODOO_DOMAIN} \
    "

Then run script.

    # for base installation
    INIT_SAAS_TOOLS=$INIT_SAAS_TOOLS_VALUE bash -x install-odoo-saas.sh

    # for docker installation:
    docker exec INIT_SAAS_TOOLS=$INIT_SAAS_TOOLS_VALUE /bin/bash /install-odoo-saas.sh
    

# Contributors

* [@yelizariev](https://github.com/yelizariev) - original semi-automated [script](https://gist.github.com/yelizariev/2abdd91d00dddc4e4fa4) for odoo installation
* [@bassn](https://github.com/bassn) - fully auto-automated [script](https://gist.github.com/bassn/996f8b168f0b1406dd54) for odoo installation
