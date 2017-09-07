FROM itprojectsllc/install-odoo:8.0

USER root

# install dependencies
RUN pip install python-escpos

RUN sed -i -e "s/^\(server_wide_modules.*\)/\1,hw_proxy,hw_posbox_homepage,hw_posbox_upgrade,hw_scale,hw_scanner,hw_escpos,hw_blackbox_be,hw_screen/" $OPENERP_SERVER

USER odoo
