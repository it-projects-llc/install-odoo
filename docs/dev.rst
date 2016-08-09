========================
 Docker for development
========================

(not finished doc)


    mkdir odoo
    cd odoo
    BASE_DIR=`pwd`
    mkdir odoo-source
    mkdir addons
    mkdir config
    mkdir data-dir
    mkdir logs
    
    # clone odoo and addons, prepare openerp config file
    ODOO_DIR=${BASE_DIR}/odoo-source \
    ADDONS_DIR=${BASE_DIR}/addons \
    CLONE_ODOO=yes \
    CLONE_IT_PROJECTS_LLC=yes \
    CLONE_OCA=yes \
    CLONE_SAAS=yes \
    OPENERP_SERVER=${BASE_DIR}/config/openerp-server.conf \
    INIT_ODOO_CONFIG=yes \
    install-odoo-saas.sh

    # run (create) container
    docker run \
    -v ${BASE_DIR}/odoo-source/:/mnt/odoo-source/ \
    -v ${BASE_DIR}/addons/:/mnt/addons/ \
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

