FROM debian:jessie

COPY install-odoo-saas.sh /

ENV OPENERP_SERVER=/mnt/config/openerp-server.conf \
    ODOO_SOURCE_DIR=/mnt/odoo-source \
    ADDONS_DIR=/mnt/extra-addons \
    ODOO_DATA_DIR=/mnt/data-dir \
    BACKUPS_DIR=/mnt/backups \
    LOGS_DIR=/mnt/logs

RUN INSTALL_DEPENDENCIES=yes \
    bash -x /install-odoo-saas.sh

RUN mkdir -p /mnt/odoo-source && chown odoo /mnt/odoo-source && \
    mkdir -p /mnt/extra-addons && chown odoo /mnt/extra-addons && \
    mkdir -p /mnt/data-dir && chown odoo /mnt/data-dir && \
    mkdir -p /mnt/config && chown odoo /mnt/config && \
    mkdir -p /mnt/backups && chown odoo /mnt/backups && \
    mkdir -p /mnt/logs && chown odoo /mnt/logs
VOLUME ["/mnt/odoo-source", \
       "/mnt/extra-addons", \
       "/mnt/data-dir", \
       "/mnt/config", \
       "/mnt/backups", \
       "/mnt/logs"]

COPY ./entrypoint.sh /

# Expose Odoo services
EXPOSE 8069 8071

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
