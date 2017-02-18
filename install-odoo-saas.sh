#!/bin/bash
# See README.md
 set -e
 INSTALL_ODOO_DIR=`pwd`
 #### GENERAL SETTINGS : Edit the following settings as needed

 # Actions
 export INSTALL_DEPENDENCIES=${INSTALL_DEPENDENCIES:-"no"}
 export INIT_POSTGRESQL=${INIT_POSTGRESQL:-"no"} # yes | no | docker-container
 export INIT_BACKUPS=${INIT_BACKUPS:-"no"} # yes | no | docker-host
 export INIT_NGINX=${INIT_NGINX:-"no"} # yes | no | docker-host
 export INIT_START_SCRIPTS=${INIT_START_SCRIPTS:-"no"} # yes | no | docker-host
 export INIT_SAAS_TOOLS=${INIT_SAAS_TOOLS:-"no"} # no | list of parameters to saas.py script
 export INIT_ODOO_CONFIG=${INIT_ODOO_CONFIG:-"no"} # no | yes | docker-container
 export INIT_USER=${INIT_USER:-"no"}
 export INIT_DIRS=${INIT_DIRS:-"no"}
 export ADD_AUTOINSTALL_MODULES=${ADD_AUTOINSTALL_MODULES:-""} # "['module1','module2']"
 export GIT_PULL=${GIT_PULL:-"no"}
 export UPDATE_ADDONS_PATH=${UPDATE_ADDONS_PATH:-"no"}
 export CLEAN=${CLEAN:-"no"}

 ## Dirs
 export ODOO_SOURCE_DIR=${ODOO_SOURCE_DIR:-"/usr/local/src/odoo-source"}
 export ADDONS_DIR=${ADDONS_DIR:-"/usr/local/src/odoo-extra-addons"}
 export ODOO_DATA_DIR=${ODOO_DATA_DIR:-"/opt/odoo/data/"}
 export BACKUPS_DIR=${BACKUPS_DIR:-"/opt/odoo/backups/"}
 export LOGS_DIR=${LOGS_DIR:-"/var/log/odoo/"}
 export OPENERP_SERVER=${OPENERP_SERVER:-/etc/openerp-server.conf}

 ## Cloning
 export CLONE_IT_PROJECTS_LLC=${CLONE_IT_PROJECTS_LLC:-"no"}
 export CLONE_OCA=${CLONE_OCA:-"no"}
 export CLONE_ODOO=${CLONE_ODOO:-"no"}

 ## Docker Names
 export ODOO_DOCKER=${ODOO_DOCKER:-"odoo"}
 export DB_ODOO_DOCKER=${DB_ODOO_DOCKER:-"db-odoo"}

 ## E-Mail
 export EMAIL_SERVER=${EMAIL_SERVER:-stmp.example.com}
 export EMAIL_USER=${EMAIL_USER:-mail@example.com}
 export EMAIL_PASS=${EMAIL_PASS:-GiveMeYourPassBaby}

 ## PostgreSQL
 export DB_PASS=${DB_PASS:-`< /dev/urandom tr -dc A-Za-z0-9 | head -c16;echo;`}

 ## Odoo
 export ODOO_DOMAIN=${ODOO_DOMAIN:-odoo.example.com}
 export ODOO_DATABASE=${ODOO_DATABASE:-odoo.example.com}
 export ODOO_USER=${ODOO_USER:-odoo}
 export ODOO_BRANCH=${ODOO_BRANCH:-10.0}
 export ODOO_MASTER_PASS=${ODOO_MASTER_PASS:-`< /dev/urandom tr -dc A-Za-z0-9 | head -c16;echo;`}

 ## Nginx
 export NGINX_SSL=${NGINX_SSL:-"no"}
 export SSL_CERT=${SSL_CERT:-/etc/nginx/XXXX.crt}
 export SSL_KEY=${SSL_KEY:-/etc/nginx/XXXX.key}

 ## wkhtmltopdf
 export WKHTMLTOPDF_DEB_URL=${WKHTMLTOPDF_DEB_URL:-""}
 export WKHTMLTOPDF_DEPENDENCIES=${WKHTMLTOPDF_DEPENDENCIES:-""}

 #### Detect type of system manager
 export SYSTEM=''
 pidof systemd && export SYSTEM='systemd'
 pidof systemd-journald && export SYSTEM='systemd'
 [[ -z $SYSTEM ]] && whereis upstart | grep -q 'upstart: /' && export SYSTEM='upstart'
 [[ -z $SYSTEM ]] &&  export SYSTEM='supervisor'
 echo "SYSTEM=$SYSTEM"

 PLATFORM=`uname -i`
 echo "PLATFORM=$PLATFORM"

 OS_RELEASE="trusty"
 # TODO rest systems
 source /etc/os-release
 if [[ $VERSION == *"Trusty"* ]]
 then
     OS_RELEASE="trusty"
 elif [[ $VERSION == *"jessie"* ]]
 then
     OS_RELEASE="jessie"
 fi
 echo "OS_RELEASE=$OS_RELEASE"


 ##### CHECK AND UPDATE LANGUAGE
 #env | grep LANG
 #export LANGUAGE=en_US:en
 #export LANG=en_US.UTF-8
 #export LC_ALL=en_US.UTF-8
 #locale-gen en_US.UTF-8 && \
 #dpkg-reconfigure locales
 #locale

 #### DOWNLOADS...

 if [[ "$INIT_NGINX" != "no" ]] || [[ "$INIT_START_SCRIPTS" != "no" ]] || [[ "$INIT_ODOO_CONFIG" != "no" ]]
 then
     # moreutils is installed for sponge util
     apt-get install -y moreutils
 fi

 [[ "$SYSTEM" == "supervisor" ]] && [[ "$INIT_START_SCRIPTS" != "no" ]] && apt-get install -y supervisor

 if [[ "$INSTALL_DEPENDENCIES" == "yes" ]]
 then
     curl --silent https://bootstrap.pypa.io/get-pip.py | python 
     apt-get install -y --no-install-recommends \
             ca-certificates \
             curl \
             node-less \
             node-clean-css \
             python-pyinotify \
             python-renderpm

     ## wkhtmltopdf
     WKHTMLTOPDF_INSTALLED="no"
     whereis wkhtmltopdf | grep -q 'wkhtmltopdf: /' && export WKHTMLTOPDF_INSTALLED='yes'
     if [[ "$WKHTMLTOPDF_DEB_URL" == "" ]] || [[ "$WKHTMLTOPDF_DEPENDENCIES" == "" ]]
     then
         WK_DEPS="xfonts-base xfonts-75dpi libjpeg62-turbo"

         # try to guess about the system
         WK_PLATFORM="i386"
         if [[ "$PLATFORM" == "x86_64" ]]
         then
             WK_PLATFORM="amd64"
         fi

         WK_OS='trusty'
         if [[ $OS_RELEASE == "trusty" ]]
         then
             WK_OS='trusty'
             WK_DEPS="xfonts-base xfonts-75dpi libjpeg-turbo8"
         fi

         if [[ "$WKHTMLTOPDF_DEB_URL" == "" ]]
         then
             WKHTMLTOPDF_DEB_URL="http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-${WK_OS}-${WK_PLATFORM}.deb"
         fi

         if [[ "$WKHTMLTOPDF_DEPENDENCIES" == "" ]]
         then
             WKHTMLTOPDF_DEPENDENCIES=$WK_DEPS
         fi

     fi
     if [[ "$WKHTMLTOPDF_INSTALLED" == "no" ]]
     then
         curl -o wkhtmltox.deb -SL ${WKHTMLTOPDF_DEB_URL}
         dpkg --force-depends -i wkhtmltox.deb
         apt-get install -y ${WKHTMLTOPDF_DEPENDENCIES} || true
         apt-get -y install -f --no-install-recommends
         apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm
         rm -rf /var/lib/apt/lists/* wkhtmltox.deb
     fi

     apt-get install -y adduser node-less node-clean-css python python-dateutil python-decorator python-docutils python-feedparser python-imaging python-jinja2 python-ldap python-libxslt1 python-lxml python-mako python-mock python-openid python-passlib python-psutil python-psycopg2 python-babel python-pychart python-pydot python-pyparsing python-pypdf python-reportlab python-requests python-suds python-tz python-vatnumber python-vobject python-werkzeug python-xlwt python-yaml
     apt-get install -y python-gevent python-simplejson

     if [[ "$ODOO_BRANCH" == "8.0" ]]
     then
         apt-get install -y python-unittest2
     fi


     pip install werkzeug --upgrade
     pip install psycogreen
     # requirements.txt
     #apt-get install -y postgresql-server-dev-all python-dev  build-essential libxml2-dev libxslt1-dev 
     #cd $ODOO_SOURCE_DIR
     #pip install -r requirements.txt

     # fix error with jpeg (if you get it)
     apt-get install -y python-dev build-essential libxml2-dev libxslt1-dev
     # uninstall PIL
     pip uninstall PIL || echo "PIL is not installed"
     if [[ "$OS_RELEASE" == "jessie" ]]
     then
         apt-get install libjpeg62-turbo-dev zlib1g-dev -y
     elif [[ "$OS_RELEASE" == "trusty" ]]
     then
         apt-get install libjpeg-dev zlib1g-dev -y
     else
         apt-get install libjpeg-dev zlib1g-dev -y
     fi
     # reinstall pillow
     pip install -I pillow
     # (from here https://github.com/odoo/odoo/issues/612 )

     # ## Less CSS via nodejs
     # ## nodejs:
     # # for 14.04+
     # apt-get install -y npm
     # ln -s /usr/bin/nodejs /usr/bin/node
     # # for 13.10-
     # # check https://www.odoo.com/documentation/8.0/setup/install.html
     # ## less css
     # npm install -g less less-plugin-clean-css


     ### Deps for Odoo Saas Tool
     # TODO replace it with deb packages
     apt-get install -y libffi-dev libssl-dev
     pip install Boto
     pip install FileChunkIO
     pip install pysftp
     pip install rotate-backups
     pip install oauthlib
     pip install requests --upgrade
 fi

 if [[ "$INIT_POSTGRESQL" != "no" ]]
 then
    ### PostgreSQL
     if [[ "$INIT_POSTGRESQL" == "docker-container" ]]
     then
         POSTGRES_PACKAGES="postgresql-client-9.5"
     else
         POSTGRES_PACKAGES="postgresql-9.5 postgresql-contrib-9.5 postgresql-client-9.5"
     fi
     apt-get install $POSTGRES_PACKAGES -y || \
         curl --silent https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
         apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 7FCC7D46ACCC4CF8 && \
         echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' >> /etc/apt/sources.list.d/pgdg.list && \
         apt-get update && \
         apt-get install $POSTGRES_PACKAGES -y
 fi

 if [[ "$INIT_USER" == "yes" ]]
 then
     ### Odoo System User
     adduser --system --quiet --shell=/bin/bash --home=/opt/${ODOO_USER} --group ${ODOO_USER} || echo 'cannot adduser'

 fi

 if [[ "$INIT_DIRS" == "yes" ]]
 then
     ### Odoo logs
     mkdir -p /var/log/odoo/
     chown ${ODOO_USER}:${ODOO_USER} /var/log/odoo

     ## /temp import data
     mkdir -p /opt/${ODOO_USER}/.local/share/User/import/
     chown -R ${ODOO_USER}:${ODOO_USER} /opt/${ODOO_USER}/.local

 fi

 ### Odoo Souce Code
 if [[ "$CLONE_ODOO" == "yes" ]]
 then
     apt-get install -y git

     mkdir -p $ODOO_SOURCE_DIR
     git clone --depth=1 -b ${ODOO_BRANCH} https://github.com/odoo/odoo.git $ODOO_SOURCE_DIR
     chown -R ${ODOO_USER}:${ODOO_USER} $ODOO_SOURCE_DIR

     #### Changes on Odoo Code
     cd $ODOO_SOURCE_DIR
     ## delete matches="..." at /web/database/manager
     sed -i 's/matches="[^"]*"//g' addons/web/static/src/xml/base.xml
 fi

 mkdir -p $ADDONS_DIR
 cd $ADDONS_DIR
 REPOS=()
 #Hint: REPOS=( "${REPOS[@]}" "new element") - is way to add element to array

 if [[ "$CLONE_OCA" == "yes" ]]
 then
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/web.git OCA/web")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/website.git OCA/website")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/account-financial-reporting.git OCA/account-financial-reporting")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/account-financial-tools.git OCA/account-financial-tools")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/partner-contact.git OCA/partner-contact")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/hr.git OCA/hr")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/pos.git OCA/pos")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/commission.git OCA/commission")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/server-tools.git OCA/server-tools")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/reporting-engine.git OCA/reporting-engine")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/rma.git OCA/rma")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/contract.git OCA/contract")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/sale-workflow.git OCA/sale-workflow")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/bank-payment.git OCA/bank-payment")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/bank-statement-import.git OCA/bank-statement-import")
     REPOS=( "${REPOS[@]}" "https://github.com/OCA/bank-statement-reconcile.git OCA/bank-statement-reconcile")
 fi

 if [[ "$CLONE_IT_PROJECTS_LLC" == "yes" ]]
 then
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/e-commerce.git it-projects-llc/e-commerce")
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/pos-addons.git it-projects-llc/pos-addons")
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/access-addons.git it-projects-llc/access-addons")
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/website-addons.git it-projects-llc/website-addons")
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/misc-addons.git it-projects-llc/misc-addons")
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/mail-addons.git it-projects-llc/mail-addons")
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/odoo-saas-tools.git it-projects-llc/odoo-saas-tools")
 fi

 if [[ "${REPOS}" != "" ]]
 then
     apt-get install -y git
 fi

 for r in "${REPOS[@]}"
 do
     eval "git clone --depth=1 -b ${ODOO_BRANCH} $r" || echo "Cannot clone: git clone -b ${ODOO_BRANCH} $r"
 done
 chown -R ${ODOO_USER}:${ODOO_USER} $ADDONS_DIR || true


 #from http://stackoverflow.com/questions/2914220/bash-templating-how-to-build-configuration-files-from-templates-with-bash
 export PERL_UPDATE_ENV="perl -p -e 's/\{\{([^}]+)\}\}/defined \$ENV{\$1} ? \$ENV{\$1} : \$&/eg' "

 if [[ "$INIT_POSTGRESQL" == "yes" ]]
 then
    ### Odoo DB User
    su - postgres bash -c "psql -c \"CREATE USER ${ODOO_USER} WITH CREATEDB PASSWORD '${DB_PASS}';\""
 fi

 if [[ "$INIT_ODOO_CONFIG" != "no" ]]
 then
     cd $INSTALL_ODOO_DIR
     if [[ "$INIT_ODOO_CONFIG" != "docker-container" ]]
     then
         cp ./configs/odoo-server.conf $OPENERP_SERVER
     fi
     eval "${PERL_UPDATE_ENV} < $OPENERP_SERVER" | sponge $OPENERP_SERVER
     chown ${ODOO_USER}:${ODOO_USER} $OPENERP_SERVER
     chmod 600 $OPENERP_SERVER
 fi


 if [[ "$UPDATE_ADDONS_PATH" == "yes" ]]
 then
     # $ADDONS_DIR:
     #
     # it-projects-llc/
     #  -> pos-addons/
     #  -> ...
     # OCA/
     #  -> pos/
     #  -> ...
     ADDONS_PATH=`ls -d1 $ADDONS_DIR/*/* | tr '\n' ','`
     ADDONS_PATH=`echo $ODOO_SOURCE_DIR/odoo/addons,$ODOO_SOURCE_DIR/addons,$ADDONS_PATH | sed "s,//,/,g" | sed "s,/,\\\\\/,g" `
     sed -ibak "s/addons_path.*/addons_path = $ADDONS_PATH/" $OPENERP_SERVER

 fi

 if [[ -n "$ADD_AUTOINSTALL_MODULES" ]]
 then
     DB_PY=$ODOO_SOURCE_DIR/odoo/service/db.py
     # add base code
     grep AUTOINSTALL_MODULES $DB_PY || \
         sed -i "s;\
            if lang:;\
            AUTOINSTALL_MODULES = []\n\
            modules = env['ir.module.module'].search([('name', 'in', AUTOINSTALL_MODULES)])\n\
            modules.button_immediate_install()\n\
            if lang:;" \
             $DB_PY
     # update module list
     sed -i "s;\
            AUTOINSTALL_MODULES = \[\];\
            AUTOINSTALL_MODULES = []\n\
            AUTOINSTALL_MODULES += $ADD_AUTOINSTALL_MODULES;" \
         $DB_PY
 fi

 if [[ "$GIT_PULL" == "yes" ]]
 then
     git -C $ODOO_SOURCE_DIR pull

     for repo in `ls -d1 $ADDONS_DIR/*/*`
     do
         git -C $repo pull
     done
 fi


 if [[ "$INIT_NGINX" != "no" ]]
 then
     #### NGINX
     CONFIGS="configs"

     /etc/init.d/apache2 stop && \
         apt-get remove apache2 -y || \
             echo "apache2 was not installed"

     #wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add - &&\
     #echo 'deb http://nginx.org/packages/ubuntu/ trusty nginx' >> /etc/apt/sources.list.d/nginx.list &&\
     #echo 'deb-src http://nginx.org/packages/ubuntu/ trusty nginx' >> /etc/apt/sources.list.d/nginx.list &&\
     apt-get install nginx -y && \
     echo "nginx installed"

     #cd /etc/nginx && \
     #mv nginx.conf nginx.conf.orig &&\
     #cp $INSTALL_ODOO_DIR/$CONFIGS/nginx.conf nginx.conf

     cd /etc/nginx
     cp $INSTALL_ODOO_DIR/$CONFIGS/nginx_odoo_params odoo_params
     eval "${PERL_UPDATE_ENV} < odoo_params" | sponge odoo_params

     #mkdir /etc/nginx/sites-available/ -p
     cd /etc/nginx/sites-available/
     cp $INSTALL_ODOO_DIR/$CONFIGS/nginx_odoo.conf odoo.conf
     eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf

     cd /etc/nginx/sites-available/
     cp $INSTALL_ODOO_DIR/$CONFIGS/nginx_odoo_ssl.conf odoo_ssl.conf
     eval "${PERL_UPDATE_ENV} < odoo_ssl.conf" | sponge odoo_ssl.conf

     #mkdir /etc/nginx/sites-enabled/ -p
     cd /etc/nginx/sites-enabled/
     rm default || true
     ln -s ../sites-available/odoo.conf odoo.conf || true


     if [[ "$NGINX_SSL" == "yes" ]]
     then
         ln -s ../sites-available/odoo_ssl.conf odoo_ssl.conf || true
     fi

     #cd /etc/nginx/ && \
     #cp -r /etc/nginx/conf.d/ /etc/nginx/conf.d.orig/
     #rm /etc/nginx/conf.d/default.conf && \
     #rm /etc/nginx/conf.d/example_ssl.conf

     /etc/init.d/nginx restart
 fi

 #### Odoo Saas Tool
 if [[ "$INIT_SAAS_TOOLS" != "no" ]]        ###################################### IF
 then
     su --preserve-environment - ${ODOO_USER} -s /bin/bash -c  "python $ADDONS_DIR/it-projects-llc/odoo-saas-tools/saas.py $INIT_SAAS_TOOLS"
 fi

 #### START CONTROL
 DAEMON_LIST=( "odoo" )
 CONFIGS="./configs"
 if [[ "$INIT_START_SCRIPTS" == "docker-host" ]]
 then
     DAEMON_LIST=( "odoo-docker" "odoo-docker-db" )
     CONFIGS="./configs-docker-host"
 fi

 if [[ "$INIT_START_SCRIPTS" != "no" ]]
 then
    echo "Control commands:"
 fi

 if [[ "$INIT_START_SCRIPTS" == "no" ]]
 then
     true
 elif [[ "$SYSTEM" == "systemd" ]]            ###################################### ELIF
 then
     ### CONTROL SCRIPTS - systemd

     cd /lib/systemd/system/

     for DAEMON in ${DAEMON_LIST[@]}
     do
         cp $INSTALL_ODOO_DIR/${CONFIGS}/${DAEMON}.service ${DAEMON}.service
         eval "${PERL_UPDATE_ENV} < ${DAEMON}.service" | sponge ${DAEMON}.service
         ## START - systemd
         systemctl enable ${DAEMON}.service
         echo "systemctl restart ${DAEMON}.service"
     done

 elif [[ "$SYSTEM" == "upstart" ]]          #################################### ELIF
 then
     ### CONTROL SCRIPTS - upstart

     cd /etc/init/
     for DAEMON in ${DAEMON_LIST[@]}
     do
         cp $INSTALL_ODOO_DIR/${CONFIGS}/${DAEMON}-init.conf ${DAEMON}.conf
         eval "${PERL_UPDATE_ENV} < ${DAEMON}.conf" | sponge ${DAEMON}.conf
         ## START - upstart
         echo "start ${DAEMON}"
         echo "stop ${DAEMON}"
         echo "restart ${DAEMON}"
     done
 else                                       #################################### ELSE
     ### CONTROL SCRIPTS - supervisor

     cd /etc/supervisor/conf.d/
     for DAEMON in ${DAEMON_LIST[@]}
     do
         cp $INSTALL_ODOO_DIR/${CONFIGS}/${DAEMON}-supervisor.conf ${DAEMON}.conf
         eval "${PERL_UPDATE_ENV} < ${DAEMON}.conf" | sponge ${DAEMON}.conf
         ## START - supervisor
         supervisorctl reread
         supervisorctl update
         echo "supervisorctl start ${DAEMON}"
         echo "supervisorctl stop ${DAEMON}"
         echo "supervisorctl restart ${DAEMON}"
     done
 fi                                         ################################   END IF

 # What?
 #echo "Do not forget to set server parameter report.url = 0.0.0.0:8069"

 #### ODOO DB BACKUP
 if [[ "$INIT_BACKUPS" != "no" ]]             ###################################### IF
 then
     if [[ "$INIT_BACKUPS" == "yes" ]]
     then
         mkdir -p ${BACKUPS_DIR}
         chown ${ODOO_USER}:${ODOO_USER} ${BACKUPS_DIR}
         cd /usr/local/bin/
         cp $INSTALL_ODOO_DIR/odoo-backup.py odoo-backup.py
         chmod +x odoo-backup.py
     fi

     if [[ "$INIT_BACKUPS" == "yes" ]]
     then
         BACKUP_EXEC="${ODOO_USER} odoo-backup.py"
     elif [[ "$INIT_BACKUPS" == "docker-host" ]]
     then
         BACKUP_EXEC="root docker exec -u root -i -t ${ODOO_DOCKER} /usr/local/bin/odoo-backup.py -d ${ODOO_DATABASE} -c ${OPENERP_SERVER} -p ${BACKUPS_DIR}"
     fi
     echo "### check url for undestanding time parameters: https://github.com/xolox/python-rotate-backups" >> /etc/crontab
     echo -e "#6 6\t* * *\t${BACKUP_EXEC} --no-save-filestore --daily 8 --weekly 0 --monthly 0 --yearly 0" >> /etc/crontab
     echo -e "#4 4\t* * 7\t${BACKUP_EXEC}" >> /etc/crontab
     ## to test run:
     # sudo su - ${ODOO_USER} -s /bin/bash -c  "odoo-backup.py -d ${ODOO_DATABASE} -p /opt/${ODOO_USER}/backups/"
     # e.g.
     # cd /usr/local/bin/ && sudo su - odoo -s /bin/bash -c  "odoo-backup.py -d ergodoo.com -p /opt/odoo/backups/"
 fi                                         ################################## END IF

if [[ "$CLEAN" == "yes" ]]
then
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false python-pip *-dev
fi
