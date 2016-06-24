#!/bin/bash
################################################################################################
# Fully automated script to install Odoo and Odoo SaaS Tool (tested on a fresh Ubuntu 14.04 LTS)
# * Install & configure last stable version of nginx
# * Install & configure last stable version of postgresql
# * Install & configure Odoo
# * Configure automated backup of Odoo databases
# * Optional: Install & configure Odoo SaaS Tool
# * Optional: Background installation: $ nohup ./odoo_install.sh > nohup.log 2>&1 </dev/null &
################################################################################################

 #### GENERAL SETTINGS : Edit the following settings as needed

 ## Type of installation
 export IS_DOCKER_HOST=${IS_DOCKER_HOST:-"no"}

 # Actions
 export INSTALL_DEPENDENCIES=${INSTALL_DEPENDENCIES:-"no"}
 export INIT_POSTGRESQL=${INIT_POSTGRESQL:-"no"}
 export INIT_BACKUPS=${INIT_BACKUPS:-"no"}
 export INIT_NGINX=${INIT_NGINX:-"no"}
 export INIT_START_SCRIPTS=${INIT_START_SCRIPTS:-"no"}
 export INIT_SAAS_TOOLS=${INIT_SAAS_TOOLS:-"no"}

 ## Dirs
 export ODOO_SOURCE_DIR=${ODOO_SOURCE_DIR:-"/usr/local/src/odoo-source"}
 export ADDONS_DIR=${ADDONS_DIR:-"/usr/local/src/odoo-extra-addons"}
 export ODOO_DATA_DIR=${ODOO_DATA_DIR:-"/opt/odoo/data/"}
 export BACKUPS_DIR=${BACKUPS_DIR:-"/opt/odoo/backups/"}
 export LOGS_DIR=${LOGS_DIR:-"/var/log/odoo/"}

 ## Cloning
 export CLONE_IT_PROJECTS_LLC=${CLONE_IT_PROJECTS_LLC:-"no"}
 export CLONE_OCA=${CLONE_OCA:-"no"}
 export CLONE_SAAS=${CLONE_SAAS:-"no"}
 export CLONE_ODOO=${CLONE_ODOO:-"no"}

 ## E-Mail
 export EMAIL_SERVER=${EMAIL_SERVER:-stmp.example.com}
 export EMAIL_USER=${EMAIL_USER:-mail@example.com}
 export EMAIL_PASS=${EMAIL_PASS:-GiveMeYourPassBaby}

 ## PostgreSQL
 export DB_PASS=${DB_PASS:-`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32};echo;`}

 ## Odoo
 export OPENERP_SERVER=${OPENERP_SERVER:-/etc/openerp-server.conf}
 export UPDATE_ADDONS_PATH=${UPDATE_ADDONS_PATH:-"no"}
 export ODOO_DOMAIN=${ODOO_DOMAIN:-odoo.example.com}
 export ODOO_DATABASE=${ODOO_DATABASE:-odoo.example.com}
 export ODOO_USER=${ODOO_USER:-odoo}
 export ODOO_BRANCH=${ODOO_BRANCH:-9.0}
 export ODOO_MASTER_PASS=${ODOO_MASTER_PASS:-`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-12};echo;`}

 ## SSL
 export SSL_CERT=${SSL_CERT:-/etc/ssl/certs/XXXX.crt}
 export SSL_KEY=${SSL_KEY:-/etc/ssl/private/XXXX.key}

 ## DB Backup
 #set "no" if you don't want to configure backup

 ## NGINX

 ## wkhtmltopdf
 # check version of your OS and download appropriate package
 # http://wkhtmltopdf.org/downloads.html

 #lsb_release -a
 #uname -i
 export WKHTMLTOPDF_DEB_URL={WKHTMLTOPDF_DEB_URL:-"http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb"}

 ## Odoo SaaS
 #set "yes" if you do want odoo saas tool. All parameters of current script are passed to saas.py

 #### Detect type of system manager
 export SYSTEM=''
 pidof systemd && export SYSTEM='systemd'
 [[ -z $SYSTEM ]] && whereis upstart | grep -q 'upstart: /' && export SYSTEM='upstart'
 [[ -z $SYSTEM ]] &&  export SYSTEM='supervisor'
 echo "SYSTEM=$SYSTEM"

 ##### CHECK AND UPDATE LANGUAGE
 #env | grep LANG
 #export LANGUAGE=en_US:en
 #export LANG=en_US.UTF-8
 #export LC_ALL=en_US.UTF-8
 #locale-gen en_US.UTF-8 && \
 #dpkg-reconfigure locales
 #locale

 #### DOWNLOADS...

 apt-get update

 if [[ "$INIT_NGINX" == "yes" ]] || [[ "$INIT_START_SCRIPTS" == "yes" ]]
 then
     apt-get install -y emacs23-nox || apt-get install -y emacs24-nox
     # moreutils is installed for sponge util
     apt-get install -y moreutils tree
 fi

 [[ "$SYSTEM" == "supervisor" ]] && [[ "$INIT_START_SCRIPTS" == "yes" ]] && apt-get install -y supervisor

 if [[ "$INSTALL_DEPENDENCIES" == "yes" ]]
 then
     apt-get install -y python-pip

     # install dependencies:
     wget http://nightly.odoo.com/9.0/nightly/deb/odoo_9.0.latest_all.deb
     sudo dpkg -i odoo_9.0.latest_all.deb  # shows errors -- just ignore them and execute next command:
     apt-get -f install
     apt-get remove odoo

     ## wkhtmltopdf
     cd /tmp
     apt-get install -y xfonts-base xfonts-75dpi
     apt-get -f install -y
     wget ${WKHTMLTOPDF_DEB_URL}
     dpkg -i wkhtmltox-*.deb

     # requirements.txt
     cd $ODOO_DIR
     pip install -r requirements.txt

     # fix error with jpeg (if you get it)
     # uninstall PIL
     pip uninstall PIL
     # install libjpeg-dev with apt
     apt-get install libjpeg-dev
     # reinstall pillow
     pip install -I pillow
     # (from here https://github.com/odoo/odoo/issues/612 )

     ## Less CSS via nodejs
     ## nodejs:
     # for 14.04+
     apt-get install -y npm
     ln -s /usr/bin/nodejs /usr/bin/node
     # for 13.10-
     # check https://www.odoo.com/documentation/8.0/setup/install.html
     ## less css
     npm install -g less less-plugin-clean-css


     if [[ "$ODOO_SAAS_TOOLS" == "yes" ]]
     then
         ### Deps for Odoo Saas Tool
         pip install Boto
         pip install FileChunkIO
         pip install pysftp
         pip install rotate-backups
         pip install oauthlib
         pip install requests --upgrade
     fi
 fi

 if [[ "$INIT_POSTGRESQL" == "yes" ]]
    ### PostgreSQL
    apt-get install postgresql
    #wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    #echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' >> /etc/apt/sources.list.d/pgdg.list &&\
    #    apt-get install postgresql postgresql-contrib -y && \
    echo "postgresql installed"
 fi

 ### Odoo Souce Code
 if [[ "$CLONE_ODOO" == "yes" ]]
 then
     mkdir -p $ODOO_DIR
     git clone -b ${ODOO_BRANCH} https://github.com/odoo/odoo.git $ODOO_DIR

     #### Changes on Odoo Code
     cd $ODOO_DIR
     ## delete matches="..." at /web/database/manager
     sed -i 's/matches="[^"]*"//g' addons/web/static/src/xml/base.xml
     ## disable im_odoo_support
     sed -i "s/'auto_install': True/'auto_install': False/" addons/im_odoo_support/__openerp__.py
 fi

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
     REPOS=( "${REPOS[@]}" "https://github.com/iledarn/e-commerce.git iledarn/e-commerce")
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/pos-addons.git it-projects-llc/pos-addons")
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/access-addons.git it-projects-llc/access-addons")
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/website-addons.git it-projects-llc/website-addons")
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/addons-it-projects-llc.git it-projects-llc/addons-it-projects-llc")
     REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/odoo-saas-tools.git it-projects-llc/odoo-saas-tools")
 fi

 if [[ "${REPOS}" != ""]]
 then
     apt-get install git
 fi

 for r in "${REPOS[@]}"
 do
     git clone -b ${ODOO_BRANCH} $r
 done

 #### CONFIGS
 ### System Config
 #from http://stackoverflow.com/questions/2914220/bash-templating-how-to-build-configuration-files-from-templates-with-bash
 export PERL_UPDATE_ENV="perl -p -e 's/\{\{([^}]+)\}\}/defined \$ENV{\$1} ? \$ENV{\$1} : \$&/eg' "

 if [[ "$INIT_POSTGRESQL" == "yes" ]]
    ### Odoo DB User
    su - postgres bash -c "psql -c \"CREATE USER ${ODOO_USER} WITH CREATEDB PASSWORD '${DB_PASS}';\""
 fi

 if [[ "$IS_DOCKER_HOST" == "no" ]]
 then

     ### Odoo System User
     #adduser --system --quiet --shell=/bin/bash --home=/opt/${ODOO_USER} --gecos '$OE_USER' --group ${ODOO_USER}

     ### Odoo Config
     echo "Odoo Config"
     ## /var/log/odoo/
     mkdir -p /var/log/odoo/
     chown ${ODOO_USER}:${ODOO_USER} /var/log/odoo

     ## /temp import data
     mkdir -p /opt/${ODOO_USER}/.local/share/User/import/
     chown -R ${ODOO_USER}:${ODOO_USER} /opt/${ODOO_USER}/.local

     ## /etc/odoo/odoo-server.conf
     mkdir -p /etc/odoo && cd /etc/odoo/
     cp ./odoo-server.conf -O odoo-server.conf
     eval "${PERL_UPDATE_ENV} < odoo-server.conf" | sponge odoo-server.conf
     chown ${ODOO_USER}:${ODOO_USER} odoo-server.conf
     chmod 600 odoo-server.conf
 fi

 if [[ "$INIT_NGINX" == "yes" ]]
 then
     #### NGINX
     #/etc/init.d/apache2 stop
     #apt-get remove apache2 -y && \
     wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add - &&\
     echo 'deb http://nginx.org/packages/ubuntu/ trusty nginx' >> /etc/apt/sources.list.d/nginx.list &&\
     echo 'deb-src http://nginx.org/packages/ubuntu/ trusty nginx' >> /etc/apt/sources.list.d/nginx.list &&\
     apt-get install nginx -y && \
     echo "nginx installed"

     cd /etc/nginx && \
     mv nginx.conf nginx.conf.orig &&\
     cp ./nginx.conf -O nginx.conf

     cd /etc/nginx && \
     cp ${CONFIGS}/nginx_odoo_params -O odoo_params && \
     eval "${PERL_UPDATE_ENV} < odoo_params" | sponge odoo_params
     mkdir /etc/nginx/sites-available/ -p && \
     cd /etc/nginx/sites-available/ && \
     cp ./nginx_odoo.conf -O odoo.conf && \
     eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf
     mkdir /etc/nginx/sites-enabled/ -p && \
     cd /etc/nginx/sites-enabled/ && \
     ln -s ../sites-available/odoo.conf odoo.conf

     #cd /etc/nginx/ && \
     cp -r /etc/nginx/conf.d/ /etc/nginx/conf.d.orig/
     rm /etc/nginx/conf.d/default.conf && \
     rm /etc/nginx/conf.d/example_ssl.conf

     /etc/init.d/nginx restart
 fi

 #### START CONTROL
 DAEMON_LIST=( "odoo" )
 CONFIGS="./configs"
 if [[ "$IS_DOCKER_HOST" == "yes" ]]
 then
     DAEMON_LIST= ( "odoo-docker" "odoo-docker-db" )
     CONFIGS="./configs-docker-host"
 fi

 if [[ "$INIT_START_SCRIPTS" == "no" ]]            ###################################### IF
 then
     # pass
 elif [[ "$SYSTEM" == "systemd" ]]            ###################################### ELIF
 then
     ### CONTROL SCRIPTS - systemd

     cd /lib/systemd/system/

     for DAEMON in $DAEMON_LIST
     do
         cp ./${CONFIGS}/${DAEMON}.service -O ${DAEMON}.service
         eval "${PERL_UPDATE_ENV} < ${DAEMON}.service" | sponge ${DAEMON}.service
         ## START - systemd
         systemctl enable ${DAEMON}.service
         systemctl restart ${DAEMON}.service
     done

 elif [[ "$SYSTEM" == "upstart" ]]          #################################### ELIF
 then
     ### CONTROL SCRIPTS - upstart

     cd /etc/init/
     for DAEMON in $DAEMON_LIST
     do
         cp ./${CONFIGS}/${DAEMON}-init.conf -O ${DAEMON}.conf
         eval "${PERL_UPDATE_ENV} < ${DAEMON}.conf" | sponge ${DAEMON}.conf
         ## START - upstart
         start ${DAEMON}     # alt: stop ${DAEMON}  / restart ${DAEMON}
     done
 else                                       #################################### ELSE
     ### CONTROL SCRIPTS - supervisor

     cd /etc/supervisor/conf.d/
     for DAEMON in $DAEMON_LIST
     do
         cp ./${CONFIGS}/${DAEMON}-supervisor.conf -O ${DAEMON}.conf
         eval "${PERL_UPDATE_ENV} < ${DAEMON}.conf" | sponge ${DAEMON}.conf
         ## START - supervisor
         supervisorctl reread
         supervisorctl update
         supervisorctl restart ${DAEMON}
     done
 fi                                         ################################   END IF

 # What?
 #echo "Do not forget to set server parameter report.url = 0.0.0.0:8069"

 #### ODOO DB BACKUP
 if [[ "$INIT_BACKUPS" == "yes" ]]             ###################################### IF
 then
     mkdir -p /opt/${ODOO_USER}/backups/
     chown ${ODOO_USER}:${ODOO_USER} /opt/${ODOO_USER}/backups/
     cd /usr/local/bin/
     cp ./odoo-backup.py -O odoo-backup.py
     chmod +x odoo-backup.py
     echo "### check url for undestanding time parameters: https://github.com/xolox/python-rotate-backups" >> /etc/crontab
     echo -e "#6 6\t* * *\t${ODOO_USER} odoo-backup.py -d ${ODOO_DATABASE} -p /opt/${ODOO_USER}/backups/ --no-save-filestore --daily 8 --weekly 0 --monthly 0 --yearly 0" >> /etc/crontab
     echo -e "#4 4\t* * 7\t${ODOO_USER} odoo-backup.py -d ${ODOO_DATABASE} -p /opt/${ODOO_USER}/backups/" >> /etc/crontab
     ## to test run:
     # sudo su - ${ODOO_USER} -s /bin/bash -c  "odoo-backup.py -d ${ODOO_DATABASE} -p /opt/${ODOO_USER}/backups/"
     # e.g.
     # cd /usr/local/bin/ && sudo su - odoo -s /bin/bash -c  "odoo-backup.py -d ergodoo.com -p /opt/odoo/backups/"
 fi                                         ################################## END IF


 #### Odoo Saas Tool
 if [[ "$ODOO_SAAS_TOOLS" == "yes" ]]        ###################################### IF
 then
     #stop odoo
     sudo su - ${ODOO_USER} -s /bin/bash -c  "python $ADDONS_DIR/it-projects-llc/odoo-saas-tools/saas.py $@"
 fi

 #### DEBUG
 ## show settings (admin password, addons path)
 head /etc/odoo/odoo-server.conf
 ## show odoo version
 grep '^version_info ' $ODOO_DIR/openerp/release.py
 ## Reminders
 echo "Do not forget PGTune: http://pgtune.leopard.in.ua/"
 ## log
 # tail -f -n 100 /var/log/odoo/odoo-server.log

 ## start from console (for ODOO_USER=odoo):
 #  sudo su - odoo -s /bin/bash -c  "/usr/local/src/odoo/openerp-server -c /etc/odoo/odoo-server.conf"

 ## psql (use name of your database)
 # sudo -u odoo psql DATABASE

 ## some common issues:
 ## https://www.odoo.com/forum/help-1/question/dataerror-new-encoding-utf8-is-incompatible-with-the-encoding-of-the-template-database-sql-ascii-52124

