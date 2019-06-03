FROM debian:jessie

#######
# ENV #
#######
ENV ODOO_BRANCH=10.0 \
    WKHTMLTOPDF_VERSION=0.12.5 \
    WKHTMLTOPDF_CHECKSUM='2583399a865d7604726da166ee7cec656b87ae0a6016e6bce7571dcd3045f98b' \
    OPENERP_SERVER=/mnt/config/odoo-server.conf \
    ODOO_SOURCE_DIR=/mnt/odoo-source \
    ADDONS_DIR=/mnt/addons \
    BACKUPS_DIR=/mnt/backups \
    LOGS_DIR=/mnt/logs \
    ODOO_DATA_DIR=/mnt/data-dir \
    LC_ALL=en_US.UTF-8

################
# dependencies #
################

# Other requirements and recommendations to run Odoo
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
        python ruby-compass \
        fontconfig libfreetype6 libxml2 libxslt1.1 libjpeg62-turbo zlib1g \
        fonts-liberation \
        libfreetype6 liblcms2-2 libopenjpeg5 libtiff5 tk tcl libpq5 \
        libldap-2.4-2 libsasl2-2 libx11-6 libxext6 libxrender1 \
        locales-all zlibc \
        bzip2 ca-certificates curl gettext-base git nano \
        openssh-client telnet xz-utils \
    && curl https://bootstrap.pypa.io/get-pip.py | python /dev/stdin \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -yqq nodejs \
    && curl -SLo fonts-liberation2.deb http://ftp.debian.org/debian/pool/main/f/fonts-liberation2/fonts-liberation2_2.00.1-3_all.deb \
    && dpkg --install fonts-liberation2.deb \
    && curl -SLo wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}-1.jessie_amd64.deb \
    && echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.deb" | sha256sum -c - \
    && (dpkg --install wkhtmltox.deb || true) \
    && apt-get install -yqq --no-install-recommends --fix-broken \
    && rm fonts-liberation2.deb wkhtmltox.deb \
    && wkhtmltopdf --version \
    && rm -Rf /var/lib/apt/lists/*

# Special case to get latest PostgreSQL client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' >> /etc/apt/sources.list.d/postgresql.list \
    && curl -SL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client \
    && rm -Rf /var/lib/apt/lists/* /tmp/*

# Special case to get latest Less and PhantomJS
RUN ln -s /usr/bin/nodejs /usr/local/bin/node \
    && npm install -g less@2 less-plugin-clean-css@1 phantomjs-prebuilt@2 \
    && rm -Rf ~/.npm /tmp/*

# Special case to get bootstrap-sass, required by Odoo for Sass assets
RUN gem install --no-rdoc --no-ri --no-update-sources bootstrap-sass --version '<3.4' \
    && rm -Rf ~/.gem /var/lib/gems/*/cache/

RUN apt-get update \
    && apt-get install -y \
       build-essential \
       libevent-dev \
       libjpeg-dev \
       libldap2-dev \
       libsasl2-dev \
       libssl-dev \
       libxml2-dev \
       libxslt1-dev \
       python-dev \
&& pip2 install openupgradelib \
&& pip2 install --no-cache-dir -r https://raw.githubusercontent.com/odoo/odoo/${ODOO_BRANCH}/requirements.txt \
&& pip2 install --no-cache-dir -r https://raw.githubusercontent.com/it-projects-llc/odoo-saas-tools/${ODOO_BRANCH}/requirements.txt \
&& pip2 install --no-cache-dir -r https://raw.githubusercontent.com/it-projects-llc/misc-addons/${ODOO_BRANCH}/requirements.txt \
&& pip2 install --no-cache-dir -r https://raw.githubusercontent.com/OCA/reporting-engine/${ODOO_BRANCH}/requirements.txt \
&& python -m compileall -q /usr/local/lib/python2.7/ || true \
&& rm -Rf /var/lib/apt/lists/*

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
    ADD_IGNORED_DATABASES="['session_store']" \
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
CMD ["/mnt/odoo-source/odoo-bin"]
