FROM itprojectsllc/install-odoo:10.0

USER root

# install dependencies
RUN pip install netifaces python-escpos

RUN sed -i -e "s/^\(server_wide_modules.*\)/\1,hw_proxy,hw_posbox_homepage,hw_scale,hw_scanner,hw_escpos,hw_blackbox_be,hw_screen/" $OPENERP_SERVER && \
    sed -i -e "s/^workers.*/workers=0/" $OPENERP_SERVER


# hw_printer_network is located in 10.0 branch, but works with earler versions too
RUN cd /tmp && \
    git clone --depth=1 -b 10.0 https://github.com/it-projects-llc/pos-addons.git && \
    cp -r /tmp/pos-addons/hw_printer_network /mnt/addons/it-projects-llc/pos-addons

USER odoo
