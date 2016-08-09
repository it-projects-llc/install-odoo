FROM debian:jessie

# install python and other common packages to have base layer
RUN apt-get update && \
    apt-get install -y git && \
    apt-get install -y python-pip && \
    apt-get install -y libffi-dev libssl-dev && \
    apt-get install -y python-gevent python-simplejson && \
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

ENV ODOO_BRANCH=9.0

COPY install-odoo-saas.sh /

run INSTALL_DEPENDENCIES=yes \
    WKHTMLTOPDF_DEB_URL="http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb" \
    WKHTMLTOPDF_DEPENDENCIES="xfonts-base xfonts-75dpi libjpeg62-turbo" \
    bash -x /install-odoo-saas.sh

#RUN CLEAN=yes \
#    bash -x /install-odoo-saas.sh

RUN mkdir -p /mnt/odoo-source && chown odoo /mnt/odoo-source && \
    mkdir -p /mnt/addons && chown odoo /mnt/addons && \
    mkdir -p /mnt/data-dir && chown odoo /mnt/data-dir && \
    mkdir -p /mnt/config && chown odoo /mnt/config && \
    mkdir -p /mnt/backups && chown odoo /mnt/backups && \
    mkdir -p /mnt/logs && chown odoo /mnt/logs

ENV CLONE_DATE=2016_08_05

RUN ODOO_DIR=/mnt/odoo-source \
    ADDONS_DIR=/mnt/addons \
    ODOO_BRANCH=${ODOO_BRANCH} \
    CLONE_ODOO=yes \
    CLONE_IT_PROJECTS_LLC=yes \
    CLONE_OCA=yes \
    CLONE_SAAS=yes \
    OPENERP_SERVER=/mnt/config/openerp-server.conf \
    INIT_ODOO_CONFIG=yes \
    bash -x install-odoo-saas.sh

COPY ./entrypoint.sh /

# Expose Odoo services
EXPOSE 8069 8071

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
