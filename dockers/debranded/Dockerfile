FROM itprojectsllc/install-odoo:latest

# install module for all new databases
ENV AUTOINSTALL_MODULES="['theme_kit']"
RUN sed -i "s;\
            if lang:;\
            module_ids = registry['ir.module.module'].search(cr, SUPERUSER_ID, [('name', 'in', ${AUTOINSTALL_MODULES})])\n\
            registry['ir.module.module'].button_immediate_install(cr, SUPERUSER_ID, module_ids)\n\
            if lang:;" \
    $ODOO_SOURCE_DIR/openerp/service/db.py

# Debrand database manager
RUN sed -i "s;<title>Odoo</title>;;" \
    $ODOO_SOURCE_DIR/addons/web/views/database_manager.html &&\
    sed -i "s;.*favicon.*;;" \
    $ODOO_SOURCE_DIR/addons/web/views/database_manager.html &&\
    sed -i "s;.*logo2.*;;" \
    $ODOO_SOURCE_DIR/addons/web/views/database_manager.html &&\
    sed -i "s;Odoo;System;" \
    $ODOO_SOURCE_DIR/addons/web/views/database_manager.html
