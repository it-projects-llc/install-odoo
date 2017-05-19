FROM itprojectsllc/install-odoo:10.0

# install module for all new databases
RUN ADD_AUTOINSTALL_MODULES="['theme_kit']" \
    bash -x install-odoo-saas.sh

# Debrand database manager
RUN sed -i "s;<title>Odoo</title>;;" \
    $ODOO_SOURCE_DIR/addons/web/views/database_manager.html &&\
    sed -i "s;.*favicon.*;;" \
    $ODOO_SOURCE_DIR/addons/web/views/database_manager.html &&\
    sed -i "s;.*logo2.*;;" \
    $ODOO_SOURCE_DIR/addons/web/views/database_manager.html &&\
    sed -i "s;Odoo;System;" \
    $ODOO_SOURCE_DIR/addons/web/views/database_manager.html
