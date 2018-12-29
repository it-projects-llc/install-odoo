FROM itprojectsllc/install-odoo:12.0-dev

USER root

# install dependencies
RUN pip install netifaces python-escpos

RUN sed -i -e "s/^\(server_wide_modules.*\)/\1,hw_proxy,hw_posbox_homepage,hw_scale,hw_scanner,hw_escpos,hw_blackbox_be,hw_screen/" $OPENERP_SERVER && \
    sed -i -e "s/^workers.*/workers=0/" $OPENERP_SERVER

COPY hw_printer_network_patch.sh /

RUN bash -x hw_printer_network_patch.sh

USER odoo
