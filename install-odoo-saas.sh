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

 ## Github script's repo
 export SCRIPT_BRANCH=${SCRIPT_BRANCH:-"yelizariev/install-odoo/master"}

 ## Docker
 export IS_DOCKER=${IS_DOCKER:-"no"}

 ## E-Mail
 export EMAIL_SERVER=${EMAIL_SERVER:-stmp.example.com}
 export EMAIL_USER=${EMAIL_USER:-mail@example.com}
 export EMAIL_PASS=${EMAIL_PASS:-GiveMeYourPassBaby}

 ## PostgreSQL
 export INIT_POSTGRESQL=${INIT_POSTGRESQL:-"yes"}
 export DB_PASS=${DB_PASS:-`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32};echo;`}

 ## Odoo
 export ODOO_DIR=${ODOO_DIR:-/usr/local/src/odoo}
 export ODOO_CONFIG=${ODOO_CONFIG:-/etc/openerp-server.conf}
 export UPDATE_ADDONS_PATH=${UPDATE_ADDONS_PATH:-"yes"}
 export CLONE_ODOO=${DB_BACKUP:-"yes"}
 export ODOO_DOMAIN=${ODOO_DOMAIN:-odoo.example.com}
 export ODOO_DATABASE=${ODOO_DATABASE:-odoo.example.com}
 export ODOO_USER=${ODOO_USER:-odoo}
 export ODOO_BRANCH=${ODOO_BRANCH:-8.0}
 export ODOO_PASS=${ODOO_PASS:-`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-12};echo;`}

 ## Addons
 export ADDONS_DIR=${ADDONS_DIR:-/usr/local/src/odoo-addons}
 export CLONE_IT_PROJECTS_LLC=${CLONE_IT_PROJECTS_LLC:-"yes"}
 export CLONE_OCA=${CLONE_OCA:-"no"}
 export CLONE_SAAS=${DB_BACKUP:-"yes"}

 ## SSL
 export SSL_CERT=${SSL_CERT:-/etc/ssl/certs/XXXX.crt}
 export SSL_KEY=${SSL_KEY:-/etc/ssl/private/XXXX.key}

 ## DB Backup
 #set "no" if you don't want to configure backup
 export DB_BACKUP=${DB_BACKUP:-"yes"}

 ## NGINX
 export INIT_NGINX=${INIT_NGINX:-"yes"}

 ## wkhtmltopdf
 # check version of your OS and download appropriate package
 # http://wkhtmltopdf.org/downloads.html
 lsb_release -a
 uname -i
 export WKHTMLTOPDF_DEB_URL={WKHTMLTOPDF_DEB_URL:-"http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb"}

 ## Odoo SaaS
 #set "yes" if you do want odoo saas tool
 export ODOO_SAAS_TOOL=${ODOO_SAAS_TOOL:-"no"}
 export SAAS_SERVER=${SAAS_SERVER:-server-1}
 export SAAS_TEMPLATE=${SAAS_TEMPLATE:-template-1}
 ## user /etc/hosts instead of dns server for saas
 #set "no" if you have dns server with odoo.example.com, server-1.odoo.example.com, template-1.odoo.example.com records
 export SAAS_ADD_HOSTS=${SAAS_ADD_HOSTS:-"yes"}

 #### Detect type of system manager
 export SYSTEM=''
 pidof systemd && export SYSTEM='systemd'
 [[ -z $SYSTEM ]] && whereis upstart | grep -q 'upstart: /' && export SYSTEM='upstart'
 [[ -z $SYSTEM ]] &&  export SYSTEM='supervisor'
 echo "SYSTEM=$SYSTEM"

 #### CHECK AND UPDATE LANGUAGE
 env | grep LANG
 export LANGUAGE=en_US:en
 export LANG=en_US.UTF-8
 export LC_ALL=en_US.UTF-8
 locale-gen en_US.UTF-8 && \
 dpkg-reconfigure locales
 locale

 #### DOWNLOADS...

 ### upgrade all installed packages
 apt-get update && \
     apt-get upgrade -y

 ### upgrade pip
 apt-get install -y python-pip && \
     pip install -U pip && \
     apt-get purge -y python-pip
 # refresh cash to be able to use new pip
 hash -r

 ### Packages
 apt-get install -y moreutils tree python-dev && \
 apt-get install -y emacs23-nox || apt-get install -y emacs24-nox  && \
 [[ "$SYSTEM" == "supervisor" ]] && [[ "$IS_DOCKER" == "no" ]] && apt-get install supervisor

 if [[ "$INIT_POSTGRESQL" == "yes" ]]
     ### PostgreSQL
     wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
     echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' >> /etc/apt/sources.list.d/pgdg.list &&\
     apt-get update &&\
     apt-get install postgresql postgresql-contrib -y && \
     echo "postgresql installed"
 fi

 ### Python
 pip install psycogreen &&\
 pip install rotate-backups &&\
 pip install oauthlib &&\
 pip install requests --upgrade

 ### Deps for OCA website
 pip install ipwhois

 ### Deps for OCA Server tools
 apt-get install python-ldap &&
 pip install unidecode &&\
 pip install unidecode --upgrade

 ### Deps for addons-vauxoo
 pip install pandas

 ### Deps for Odoo Saas Tool
 pip install Boto
 pip install FileChunkIO
 pip install pysftp

 ### Odoo Souce Code
 # If you change the following directories, you muss also ajust line 2 of file odoo-server.conf below
 if [[ "$CLONE_ODOO" == "yes" ]]
 then
    apt-get install -y git &&\
        mkdir -p $ODOO_DIR  &&\
        git clone -b ${ODOO_BRANCH} https://github.com/odoo/odoo.git $ODOO_DIR
 fi

 REPOS=()
 #REPOS=( "${REPOS[@]}" "new element") - is way to add element to array

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

 for r in "${REPOS[@]}"
 do
     git clone -b ${ODOO_BRANCH} $r
 done

 ### Odoo Deps
 ## python
 python --version                      # should be 2.7 or higher
 cd ${ODOO_DIR} &&\
 cp odoo.py odoo.py.orig &&\
 sed -i "s/'apt-get'/'apt-get', '-y'/" odoo.py &&\
 cat odoo.py | python &&\
 git checkout odoo.py
 echo "odoo.py checked out"

 ## wkhtmltopdf
 cd /tmp
 apt-get install -y xfonts-base xfonts-75dpi
 apt-get -f install -y
 wget ${WKHTMLTOPDF_DEB_URL}
 dpkg -i wkhtmltox-*.deb

 ## Less CSS via nodejs
 ## nodejs:
 # for 14.04+
 apt-get install -y npm
 ln -s /usr/bin/nodejs /usr/bin/node
 # for 13.10-
 # check https://www.odoo.com/documentation/8.0/setup/install.html
 ## less css
 npm install -g less less-plugin-clean-css
 #### ...DOWNLOADS done.

 #### Changes on Odoo Code
 cd /usr/local/src/odoo
 ## delete matches="..." at /web/database/manager
 sed -i 's/matches="[^"]*"//g' addons/web/static/src/xml/base.xml
 ## disable im_odoo_support
 sed -i "s/'auto_install': True/'auto_install': False/" addons/im_odoo_support/__openerp__.py

 #### CONFIGS
 ### System Config
 #from http://stackoverflow.com/questions/2914220/bash-templating-how-to-build-configuration-files-from-templates-with-bash
 export PERL_UPDATE_ENV="perl -p -e 's/\{\{([^}]+)\}\}/defined \$ENV{\$1} ? \$ENV{\$1} : \$&/eg' "
 [[ -z $SYSTEM ]] && echo "Don't forget to define SYSTEM variable"

 ### Odoo System User
 adduser --system --quiet --shell=/bin/bash --home=/opt/${ODOO_USER} --gecos '$OE_USER' --group ${ODOO_USER}

 if [[ "$INIT_POSTGRESQL" == "yes" ]]
    ### Odoo DB User
    su - postgres bash -c "psql -c \"CREATE USER ${ODOO_USER} WITH CREATEDB PASSWORD '${DB_PASS}';\""
 fi

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
 wget -q https://raw.githubusercontent.com/${SCRIPT_BRANCH}/odoo-server.conf -O odoo-server.conf
 eval "${PERL_UPDATE_ENV} < odoo-server.conf" | sponge odoo-server.conf
 chown ${ODOO_USER}:${ODOO_USER} odoo-server.conf
 chmod 600 odoo-server.conf


 if [[ "$INIT_NGINX" == "yes" ]]
 then
     #### NGINX
     #/etc/init.d/apache2 stop
     #apt-get remove apache2 -y && \
     wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add - &&\
     echo 'deb http://nginx.org/packages/ubuntu/ trusty nginx' >> /etc/apt/sources.list.d/nginx.list &&\
     echo 'deb-src http://nginx.org/packages/ubuntu/ trusty nginx' >> /etc/apt/sources.list.d/nginx.list &&\
     apt-get update &&\
     apt-get install nginx -y && \
     echo "nginx installed"

     cd /etc/nginx && \
     mv nginx.conf nginx.conf.orig &&\
     wget -q https://raw.githubusercontent.com/${SCRIPT_BRANCH}/nginx.conf -O nginx.conf

     cd /etc/nginx && \
     wget -q  https://raw.githubusercontent.com/${SCRIPT_BRANCH}/nginx_odoo_params -O odoo_params && \
     eval "${PERL_UPDATE_ENV} < odoo_params" | sponge odoo_params
     mkdir /etc/nginx/sites-available/ -p && \
     cd /etc/nginx/sites-available/ && \
     wget -q https://raw.githubusercontent.com/${SCRIPT_BRANCH}/nginx_odoo.conf -O odoo.conf && \
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
 ### CONTROL SCRIPTS - systemd
 if [[ "$IS_DOCKER" == "yes" ]]            ###################################### IF
 then

     # no need for start scripts in docker

 elif [[ "$SYSTEM" == "systemd" ]]            ###################################### IF
 then

     cd /lib/systemd/system/
     wget -q https://raw.githubusercontent.com/${SCRIPT_BRANCH}/odoo.service -O odoo.service
     eval "${PERL_UPDATE_ENV} < odoo.service" | sponge odoo.service
     ## START - systemd
     systemctl enable odoo.service
     systemctl restart odoo.service

 ### CONTROL SCRIPTS - upstart
 elif [[ "$SYSTEM" == "upstart" ]]          #################################### ELIF
 then

     cd /etc/init/
     wget -q https://raw.githubusercontent.com/${SCRIPT_BRANCH}/odoo-init.conf -O odoo.conf
     eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf
     ## START - upstart
     start odoo     # alt: stop odoo  / restart odoo

 ### CONTROL SCRIPTS - supervisor
 else                                       #################################### ELSE

     cd /etc/supervisor/conf.d/
     wget -q https://raw.githubusercontent.com/${SCRIPT_BRANCH}/odoo-supervisor.conf -O odoo.conf
     eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf
     ## START - supervisor
     supervisorctl reread
     supervisorctl update
     supervisorctl restart odoo

 fi                                         ################################   END IF

 echo "Do not forget to set server parameter report.url = 0.0.0.0:8069"

 ### CONTROL SCRIPTS - /etc/init.d/*
 # Such scripts are not recommended, because you will not get supervision features.
 # Use this link to find ones: https://gist.github.com/yelizariev/2abdd91d00dddc4e4fa4/d0ac3bd971e81213d17332647d9a74a580cfde6b


 #### ODOO DB BACKUP
 if [[ "$DB_BACKUP" == "yes" ]]             ###################################### IF
 then
     mkdir -p /opt/${ODOO_USER}/backups/
     chown ${ODOO_USER}:${ODOO_USER} /opt/${ODOO_USER}/backups/
     cd /usr/local/bin/
     wget -q https://raw.githubusercontent.com/${SCRIPT_BRANCH}/odoo-backup.py -O odoo-backup.py
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
 if [[ "$ODOO_SAAS_TOOL" == "yes" ]]        ###################################### IF
 then
 if [[ "$SAAS_ADD_HOSTS" == "yes" ]]
 then
 /bin/bash -c  "python /usr/local/src/odoo-addons/yelizariev/odoo-saas-tools/saas.py \
  --print-local-hosts \
  --portal-db-name=${ODOO_DOMAIN} \
  --server-db-name=${SAAS_SERVER}.${ODOO_DOMAIN} \
  --plan-template-db-name=${SAAS_TEMPLATE}.${ODOO_DOMAIN} \
  >> /etc/hosts"
 fi

 #emacs /etc/odoo/odoo-server.conf # change dbfilter to ^%h$ if needed
 echo $ODOO_PASS
 echo $ODOO_DOMAIN
 stop odoo
 sudo su - ${ODOO_USER} -s /bin/bash -c  "python /usr/local/src/odoo-addons/yelizariev/odoo-saas-tools/saas.py \
  --odoo-script=/usr/local/src/odoo/openerp-server \
  --odoo-config=/etc/odoo/odoo-server.conf \
  --portal-create --server-create --plan-create --run  \
  --admin-password=${ODOO_PASS} \
  --portal-db-name=${ODOO_DOMAIN} \
  --server-db-name=${SAAS_SERVER}.${ODOO_DOMAIN} \
  --plan-template-db-name=${SAAS_TEMPLATE}.${ODOO_DOMAIN} \
  --plan-clients=demo-%i.${ODOO_DOMAIN}"
 fi                                         ################################## END IF

 #### DEBUG
 ## show settings (admin password, addons path)
 head /etc/odoo/odoo-server.conf
 ## show odoo version
 grep '^version_info ' /usr/local/src/odoo/openerp/release.py
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

