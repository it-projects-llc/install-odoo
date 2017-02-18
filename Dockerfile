FROM debian:jessie

################
# dependencies #
################
RUN apt-get update && \
    apt-get install -y moreutils && \
    apt-get install -y git && \
    apt-get install -y libffi-dev libssl-dev && \
    apt-get install -y python-gevent python-simplejson && \
    apt-get install -y xfonts-base xfonts-75dpi libjpeg62-turbo && \
    apt-get install -y python-dev build-essential libxml2-dev libxslt1-dev && \
    apt-get install -y libjpeg62-turbo-dev zlib1g-dev && \
    apt-get install -y adduser node-less node-clean-css python python-dateutil python-decorator python-docutils python-feedparser python-imaging python-jinja2 python-ldap python-libxslt1 python-lxml python-mako python-mock python-openid python-passlib python-psutil python-psycopg2 python-babel python-pychart python-pydot python-pyparsing python-pypdf python-reportlab python-requests python-suds python-tz python-vatnumber python-vobject python-werkzeug python-xlwt python-yaml && \
    apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            node-less \
            node-clean-css \
            python-pyinotify \
            python-renderpm && \
    # postgresql-client-9.5
    curl --silent https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' >> /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y postgresql-client-9.5 && \
    # wkhtmltopdf
    curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb && \
    dpkg --force-depends -i wkhtmltox.deb && \
    apt-get -y install -f --no-install-recommends && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm && \
    rm -rf /var/lib/apt/lists/* wkhtmltox.deb && \
    # pip dependencies
    curl --silent https://bootstrap.pypa.io/get-pip.py | python && \
    pip install werkzeug --upgrade && \
    pip install pillow psycogreen && \
    pip install Boto && \
    pip install FileChunkIO && \
    pip install pysftp && \
    pip install rotate-backups && \
    pip install oauthlib && \
    pip install requests --upgrade && \
    # check that pip is not broken after requests --upgrade
    pip --version


#######
# ENV #
#######
ENV ODOO_BRANCH=10.0 \
    OPENERP_SERVER=/mnt/config/odoo-server.conf \
    ODOO_SOURCE_DIR=/mnt/odoo-source \
    ADDONS_DIR=/mnt/addons \
    BACKUPS_DIR=/mnt/backups \
    LOGS_DIR=/mnt/logs \
    ODOO_DATA_DIR=/mnt/data-dir \
    BUILD_DATE=2016_10_20

#####################################
# odoo source, user, docker folders #
#####################################
RUN git clone --depth=1 -b ${ODOO_BRANCH} https://github.com/odoo/odoo.git $ODOO_SOURCE_DIR && \
    adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --group odoo && \
    chown -R odoo:odoo $ODOO_SOURCE_DIR && \
    mkdir -p $ODOO_SOURCE_DIR && chown odoo $ODOO_SOURCE_DIR && \
    mkdir -p $ADDONS_DIR/extra && chown -R odoo $ADDONS_DIR && \
    mkdir -p $ODOO_DATA_DIR && chown odoo $ODOO_DATA_DIR && \
    mkdir -p /mnt/config && chown odoo /mnt/config && \
    mkdir -p $BACKUPS_DIR && chown odoo $BACKUPS_DIR && \
    mkdir -p $LOGS_DIR && chown odoo $LOGS_DIR

###############################################
# config, scripts, repos, autoinstall modules #
###############################################
COPY install-odoo-saas.sh /
COPY configs-docker-container/odoo-server.conf $OPENERP_SERVER
COPY odoo-backup.py /usr/local/bin/

RUN chmod +x /usr/local/bin/odoo-backup.py && \
    chown odoo:odoo $OPENERP_SERVER && \
    CLONE_IT_PROJECTS_LLC=yes \
    CLONE_OCA=yes \
    INIT_ODOO_CONFIG=docker-container \
    UPDATE_ADDONS_PATH=yes \
    ADD_AUTOINSTALL_MODULES="['ir_attachment_force_storage', 'base_session_store_psql']" \
    bash -x install-odoo-saas.sh

COPY reset-admin-passwords.py /

########################
# docker configuration #
########################
COPY ./entrypoint.sh /
EXPOSE 8069 8072
USER odoo
VOLUME ["/mnt/data-dir", \
       "/mnt/backups", \
       "/mnt/logs", \
       "/mnt/addons/extra"]
# /mnt/addons/extra is used for manually added addons.
# Expected structure is:
# /mnt/addons/extra/REPO_OR_GROUP_NAME/MODULE/__openerp__.py
#
# we don't add /mnt/odoo-source, /mnt/addons, /mnt/config to VOLUME in order to allow modify theirs content in inherited dockers

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/mnt/odoo-source/odoo-bin", "--load=web,web_kanban,base_session_store_psql"]
