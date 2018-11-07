FROM itprojectsllc/install-odoo:12.0-dev

USER root

RUN mkdir $ADDONS_DIR/codup && cd $ADDONS_DIR/codup && git clone --depth=1 -b ${ODOO_BRANCH} https://github.com/codup/odoo-ru.git

RUN UPDATE_ADDONS_PATH=yes \
    bash -x /install-odoo-saas.sh

USER odoo
