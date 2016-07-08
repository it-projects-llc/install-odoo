FROM debian:jessie

# install python and other common packages to have base layer
RUN apt-get update && \
    apt-get install -y python-pip && \
    apt-get install -y xfonts-base xfonts-75dpi libjpeg62-turbo && \
    apt-get install -y python-dev build-essential libxml2-dev libxslt1-dev && \
    apt-get install -y libjpeg62-turbo-dev zlib1g-dev && \
    apt-get install -y adduser node-less node-clean-css postgresql-client python python-dateutil python-decorator python-docutils python-feedparser python-imaging python-jinja2 python-ldap python-libxslt1 python-lxml python-mako python-mock python-openid python-passlib python-psutil python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-pypdf python-reportlab python-requests python-suds python-tz python-vatnumber python-vobject python-werkzeug python-xlwt python-yaml && \
    apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            node-less \
            node-clean-css \
            python-pyinotify \
            python-renderpm \
            python-support

COPY install-odoo-saas.sh /

ENV OPENERP_SERVER=/mnt/config/openerp-server.conf \
    ODOO_SOURCE_DIR=/mnt/odoo-source \
    ADDONS_DIR=/mnt/extra-addons \
    ODOO_DATA_DIR=/mnt/data-dir \
    BACKUPS_DIR=/mnt/backups \
    LOGS_DIR=/mnt/logs

RUN INSTALL_DEPENDENCIES=yes \
    WKHTMLTOPDF_DEB_URL="http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb" \
    WKHTMLTOPDF_DEPENDENCIES="xfonts-base xfonts-75dpi libjpeg62-turbo" \
    bash -x /install-odoo-saas.sh

#RUN CLEAN=yes \
#    bash -x /install-odoo-saas.sh

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
