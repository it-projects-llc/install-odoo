FROM debian:stretch

################
# dependencies #
################

# Other requirements and recommendations to run Odoo
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
RUN apt-get -qq update \
    && apt-get -yqq upgrade \
    && apt-get install -yqq --no-install-recommends \
        python3 ruby-compass \
        fontconfig libfreetype6 libxml2 libxslt1.1 libjpeg62-turbo zlib1g \
        libfreetype6 liblcms2-2 libtiff5 tk tcl libpq5 \
        libldap-2.4-2 libsasl2-2 libx11-6 libxext6 libxrender1 \
        locales-all zlibc \
        bzip2 ca-certificates curl gettext-base git gnupg2 nano \
        openssh-client postgresql-client telnet xz-utils \
    && curl https://bootstrap.pypa.io/get-pip.py | python3 /dev/stdin --no-cache-dir \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -yqq nodejs \
    && apt-get -yqq purge python2.7 \
    && apt-get -yqq autoremove \
    && rm -Rf /var/lib/apt/lists/*

# Special case to get latest Less and PhantomJS
RUN ln -s /usr/bin/nodejs /usr/local/bin/node \
    && npm install -g less phantomjs-prebuilt \
    && rm -Rf ~/.npm /tmp/*

# Special case to get bootstrap-sass, required by Odoo for Sass assets
RUN gem install --no-rdoc --no-ri --no-update-sources bootstrap-sass --version '<4' \
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
        python3-dev \
        zlib1g-dev

RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            node-less \
            python3-pip \
            python3-setuptools \
            python3-renderpm \
            libssl1.0-dev \
            xz-utils \
            git \
            python3-psutil \
            libxrender1 \
            libfontconfig1 \
            gnupg2 \
        && curl -o wkhtmltox.tar.xz -SL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
        && echo '3f923f425d345940089e44c1466f6408b9619562 wkhtmltox.tar.xz' | sha1sum -c - \
        && tar xvf wkhtmltox.tar.xz \
        && cp wkhtmltox/lib/* /usr/local/lib/ \
        && cp wkhtmltox/bin/* /usr/local/bin/ \
        && cp -r wkhtmltox/share/man/man1 /usr/local/share/man/ \
        && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
        && apt-get install -yqq nodejs \
        && apt-get -yqq purge python2.7 \
        # pip3 dependencies
        && pip3 install pypdf2 \
            passlib \
            babel \
            werkzeug \
            lxml \
            decorator \
            python-dateutil \
            pyyaml \
            psycopg2 \
            pillow \
            requests \
            jinja2 \
            reportlab \
            html2text \
            docutils \
            num2words \
            simplejson \
            gevent \
            Boto \
            pysftp \
            oauthlib

#######
# ENV #
#######
ENV ODOO_BRANCH=11.0 \
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
