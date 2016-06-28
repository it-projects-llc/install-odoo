# install-odoo

Install odoo from git with\without using docker for developement\production.

## Basic usage

    git clone https://github.com/yelizariev/install-odoo.git

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
    CLONE_SAAS=yes \
    OPENERP_SERVER=/etc/openerp-server.conf
    UPDATE_ADDONS_PATH=yes \
    /bin/bash -x install-odoo-saas.sh

## Install in Docker

    # build image
    cd /path/to/install-odoo/
    docker build -t install-odoo-dev -f .

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

# Contributors

* [@yelizariev](https://github.com/yelizariev) - original semi-automated [script](https://gist.github.com/yelizariev/2abdd91d00dddc4e4fa4) for odoo installation
* [@bassn](https://github.com/bassn) - fully auto-automated [script](https://gist.github.com/bassn/996f8b168f0b1406dd54) for odoo installation
