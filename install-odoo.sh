#!/bin/bash
################################################################################
#
################################################################################
#if [ "$(basename $0)" = "install-odoo.sh" ]; then
#  echo "don't run install-odoo.sh, because it's not fully automated script. Copy, paste and execute commands from this file manually"
#  exit 0
#fi


 #### Detect type of system manager
 export SYSTEM=''
 pidof systemd && export SYSTEM='systemd' 
 [[ -z $SYSTEM ]] && whereis upstart | grep -q 'upstart: /' && export SYSTEM='upstart'
 [[ -z $SYSTEM ]] &&  export SYSTEM='supervisor'
 echo "SYSTEM=$SYSTEM"

 #### CHECK AND UPDATE LANGUAGE
 env | grep LANG
 export LANGUAGE=en_US:en && \
 export LANG=en_US.UTF-8 && \
 export LC_ALL=en_US.UTF-8 && \
 locale-gen en_US.UTF-8 && \
 dpkg-reconfigure locales
 locale


 #### DOWNLOADS...

 ### PACKAGES
 apt-get update && \
 apt-get upgrade -y && \
 apt-get install -y git python-pip moreutils tree && \
 apt-get install -y emacs23-nox || apt-get install -y emacs24-nox  && \
 [[ "$SYSTEM" == "supervisor" ]] && apt-get install supervisor


 ###PostgreSQL
 
 wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
 echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' >> /etc/apt/sources.list.d/pgdg.list &&\
 apt-get update &&\
 apt-get install postgresql postgresql-contrib -y && \
 echo "postgresql installed"
 
 ###PG Settings
 export PG_MAIN="/etc/postgresql/9.5/main"      
 export PG_CONF="${PG_MAIN}/postgresql.conf"
 export PG_HBA="${PG_MAIN}/pg_hba.conf"
 #tbd
 
 ## pythons
 #pip install gdata &&\
 #apt-get install python-gdata -y &&\
 pip install psycogreen &&\
 pip install rotate-backups &&\
 pip install oauthlib &&\
 pip install requests --upgrade
 #pip install gevent &&\              FIX-ME
 #pip install gevent_psycopg2 &&\     FIX-ME
 
 ## OCA Server tools
 #pip install ldap &&\
 apt-get install python-ldap &&
 pip install unidecode &&\
 pip install unidecode --upgrade

 ## Odoo Saas Tool
 pip install Boto 
 pip install FileChunkIO
 #pysftp : i had to dwonlaod it from source to get it work!
 wget https://pypi.python.org/packages/source/p/pysftp/pysftp-0.2.8.tar.gz
 tar -xzf pysftp-0.2.8.tar.gz
 cd pysftp-0.2.8/ 
 python setup.py install
 
 
 ### SOURCE
 
 export ODOO_BRANCH=8.0
 
 cd /usr/local/src/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/odoo/odoo.git &&\
 mkdir /usr/local/src/odoo-addons -p && cd /usr/local/src/odoo-addons/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/OCA/web.git OCA/web/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/OCA/account-financial-reporting.git OCA/account-financial-reporting/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/OCA/account-financial-tools.git OCA/account-financial-tools/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/OCA/partner-contact.git OCA/partner-contact/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/OCA/hr.git OCA/hr/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/OCA/pos.git OCA/pos/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/OCA/commission.git OCA/commission/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/OCA/server-tools.git OCA/server-tools/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/yelizariev/pos-addons.git yelizariev/pos-addons/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/yelizariev/website-addons.git yelizariev/website-addons/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/yelizariev/addons-yelizariev.git yelizariev/addons-yelizariev/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/yelizariev/odoo-saas-tools.git yelizariev/odoo-saas-tools/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/iledarn/e-commerce.git iledarn/e-commerce/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/xpansa/hr.git xpansa/hr/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/odoomrp/odoomrp-wip.git odoomrp/odoomrp-wip/ &&\
 git clone -b ${ODOO_BRANCH} https://github.com/odoomrp/odoomrp-utils.git odoomrp/odoomrp-utils/ &&\
 # manual collection of modules
 mkdir -p ergobit &&\
 mkdir -p x-community &&\ 
 mkdir -p x-community-p &&\
 mkdir -p vauxoo
 # some OCA module which do not work

 ### DEPS
 python --version        # should be 2.7 or higher

 cd /usr/local/src/odoo &&\
 cp odoo.py odoo.py.orig &&\
 sed -i "s/'apt-get'/'apt-get', '-y'/" odoo.py &&\
 cat odoo.py | python &&\
 git checkout odoo.py


 ## wkhtmltopdf
 cd /usr/local/src
 lsb_release -a 
 uname -i
 # check version of your OS and download appropriate package
 # http://wkhtmltopdf.org/downloads.html
 apt-get install -y xfonts-base xfonts-75dpi
 apt-get -f install
 wget http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
 dpkg -i wkhtmltox-*.deb

 #@@@@@@@@@@@@@@@@@@@@ NEED MANUAL WORK HERE (FIXME)
 ## Less CSS via nodejs
 ## nodejs:
 # 14.04 +
 apt-get install -y npm
 ln -s /usr/bin/nodejs /usr/bin/node
 # 13.10-
 # check https://www.odoo.com/documentation/8.0/setup/install.html
 ## less css
 npm install -g less less-plugin-clean-css
 
#### DOWNLOADS done.


 ### SETTINGS
 ## gist url --  update it if you've forked this gist
 export GIST="bassn/996f8b168f0b1406dd54"
 ## from http://stackoverflow.com/questions/2914220/bash-templating-how-to-build-configuration-files-from-templates-with-bash
 export PERL_UPDATE_ENV="perl -p -e 's/\{\{([^}]+)\}\}/defined \$ENV{\$1} ? \$ENV{\$1} : \$&/eg' "
 export ODOO_DOMAIN=ergodoo.com
 export ODOO_DATABASE=ergodoo.com
 export ODOO_USER=odoo
 #export ODOO_BRANCH=x.y  is done above
 export ODOO_PASS=`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32};echo;`
 export DB_PASS=`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32};echo;`
 [[ -z $SYSTEM ]] && echo "Don't forget to define SYSTEM variable"


 adduser --system --quiet --shell=/bin/bash --home=/opt/${ODOO_USER} --gecos '$OE_USER' --group ${ODOO_USER}

 # psql --version
 # pg_createcluster 9.3 main --start
 #sudo -iu postgres createuser -s ${ODOO_USER}
 #sudo su - postgres -c "createuser --createdb --username postgres --pwprompt ${ODOO_USER}"
 #sudo su - postgres -c "createuser --createdb --username postgres ${ODOO_USER}"
 sudo su - postgres bash -c "psql -c \"CREATE USER ${ODOO_USER} WITH CREATEDB PASSWORD '${DB_PASS}';\""


 ### BRANCH
 cd /usr/local/src/odoo

 # git checkout -b ${ODOO_BRANCH} origin/${ODOO_BRANCH}  #branch already exist
 ## delete matches="..." at /web/database/manager
 cp addons/web/static/src/xml/base.xml addons/web/static/src/xml/base.xml.orig
 sed -i 's/matches="[^"]*"//g' addons/web/static/src/xml/base.xml


 ### CONFIGS
 echo "CONFIG"
 ## /var/log/odoo/
 mkdir -p /var/log/odoo/
 chown ${ODOO_USER}:${ODOO_USER} /var/log/odoo

 ## /temp import data
 mkdir -p /opt/{{ODOO_USER}}/.local/share/Import/
 chown ${ODOO_USER}:${ODOO_USER} /opt/{{ODOO_USER}}/.local/share/Import
 
 ## /etc/odoo/odoo-server.conf
 mkdir -p /etc/odoo && cd /etc/odoo/
 wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-server.conf -O odoo-server.conf
 eval "${PERL_UPDATE_ENV} < odoo-server.conf" | sponge odoo-server.conf
 chown ${ODOO_USER}:${ODOO_USER} odoo-server.conf
 chmod 600 odoo-server.conf


 ### NGINX
 #/etc/init.d/apache2 stop
 #apt-get remove apache2 -y && \
 wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add - &&\
 echo 'deb http://nginx.org/packages/ubuntu/ trusty nginx' >> /etc/apt/sources.list.d/nginx.list &&\
 echo 'deb-src http://nginx.org/packages/ubuntu/ trusty nginx' >> /etc/apt/sources.list.d/nginx.list &&\
 apt-get update &&\
 apt-get install nginx -y && \
 echo "nginx installed"

 cd /etc/nginx && \
 wget -q https://gist.githubusercontent.com/${GIST}/raw/nginx_odoo_params -O odoo_params && \
 eval "${PERL_UPDATE_ENV} < odoo_params" | sponge odoo_params

 mkdir /etc/nginx/sites-available/ -p && \
 cd /etc/nginx/sites-available/ && \
 wget -q https://gist.githubusercontent.com/${GIST}/raw/nginx_odoo.conf -O odoo.conf && \
 eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf
 mkdir /etc/nginx/sites-enabled/ -p && \
 cd /etc/nginx/sites-enabled/ && \
 ln -s ../sites-available/odoo.conf odoo.conf 
 
# cd /etc/nginx/ && \
 cp -r /etc/nginx/conf.d/ /etc/nginx/conf.d.orig/  
 rm /etc/nginx/conf.d/default.conf && \
 rm /etc/nginx/conf.d/example_ssl.conf

 /etc/init.d/nginx restart


 ### CONTROL SCRIPTS - systemd
 if [[ "$SYSTEM" == "systemd" ]] ###################################### IF
 then

 cd /lib/systemd/system/

 wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo.service -O odoo.service
 eval "${PERL_UPDATE_ENV} < odoo.service" | sponge odoo.service

 #wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-longpolling.service -O odoo-longpolling.service
 #eval "${PERL_UPDATE_ENV} < odoo-longpolling.service" | sponge odoo-longpolling.service


 ### START - systemd

 systemctl enable odoo.service #&& systemctl enable odoo-longpolling.service
 systemctl restart odoo.service #&& systemctl restart odoo-longpolling.service

 ### CONTROL SCRIPTS - upstart
 elif [[ "$SYSTEM" == "upstart" ]] ###################################### ELIF
 then

 cd /etc/init/

 wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-init.conf -O odoo.conf
 eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf

 #wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-longpolling-init.conf -O odoo-longpolling.conf
 #eval "${PERL_UPDATE_ENV} < odoo-longpolling.conf" | sponge odoo-longpolling.conf


 ### START - upstart

 start odoo #&& start odoo-longpolling
 # stop odoo #&& stop odoo-longpolling
 # restart odoo #&& restart odoo-longpolling

 ### CONTROL SCRIPTS - supervisor
 else ###################################################### ELSE

 cd /etc/supervisor/conf.d/

 wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-supervisor.conf -O odoo.conf
 eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf

 #wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-longpolling-supervisor.conf -O odoo-longpolling.conf
 #eval "${PERL_UPDATE_ENV} < odoo-longpolling.conf" | sponge odoo-longpolling.conf

 ### START - supervisor
supervisorctl reread
supervisorctl update

supervisorctl restart odoo #&& supervisorctl restart odoo-longpolling

 fi ####################################################   END IF

 echo "Do not forget to set server parameter report.url = 0.0.0.0:8069"

 ### CONTROL SCRIPTS - /etc/init.d/*
 # Such scripts are not recommended, because you will not get supervision features.
 # Use this link to find ones: https://gist.github.com/yelizariev/2abdd91d00dddc4e4fa4/d0ac3bd971e81213d17332647d9a74a580cfde6b
 

 ### BACKUP
 mkdir -p /opt/${ODOO_USER}/backups/
 chown ${ODOO_USER}:${ODOO_USER} /opt/${ODOO_USER}/backups/
 cd /usr/local/bin/
 wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-backup.py -O odoo-backup.py
 chmod +x odoo-backup.py
 echo "### check url for undestanding time parameters: https://github.com/xolox/python-rotate-backups" >> /etc/crontab
 echo -e "#6 6\t* * *\t${ODOO_USER} odoo-backup.py -d ${ODOO_DATABASE} -p /opt/${ODOO_USER}/backups/ --no-save-filestore --daily 8 --weekly 0 --monthly 0 --yearly 0" >> /etc/crontab
 echo -e "#4 4\t* * 7\t${ODOO_USER} odoo-backup.py -d ${ODOO_DATABASE} -p /opt/${ODOO_USER}/backups/" >> /etc/crontab
 ## to test run:
 # sudo su - ${ODOO_USER} -s /bin/bash -c  "odoo-backup.py -d ${ODOO_DATABASE} -p /opt/${ODOO_USER}/backups/"


 ### SAAS

 # To deploy saas stop odoo and execute
 emacs /etc/odoo/odoo-server.conf # change dbfilter to ^%h$
 #export ODOO_DOMAIN=ergodoo.com    #already done above
 echo $ODOO_PASS
 
 sudo su - ${ODOO_USER} -s /bin/bash -c  "python /usr/local/src/odoo-addons/odoo-saas-tools/saas.py \
  --odoo-script=/usr/local/src/odoo/openerp-server \
  --odoo-config=/etc/odoo/odoo-server.conf \
  --portal-create --server-create --plan-create --run  \
  --admin-password=${ODOO_PASS} \
  --portal-db-name=${ODOO_DOMAIN} \
  --server-db-name=server-1.${ODOO_DOMAIN} \
  --plan-template-db-name=template-1.${ODOO_DOMAIN} \
  --plan-clients=demo-%i.${ODOO_DOMAIN}"
 


 ### DEBUG

 ## show settings (admin password, addons path)
 head /etc/odoo/odoo-server.conf 
 
 ## show odoo version
 grep '^version_info ' /usr/local/src/odoo/openerp/release.py 

 ## Reminders
 echo "Do not forget PGTune: http://pgtune.leopard.in.ua/"
 
 
 ## log
 tail -f -n 100 /var/log/odoo/odoo-server.log 
 #tail -f /var/log/odoo/odoo-server.log 

 ## start from console (for ODOO_USER=odoo): 
 #  sudo su - odoo -s /bin/bash -c  "/usr/local/src/odoo/openerp-server -c /etc/odoo/odoo-server.conf"

 ## psql (use name of your database)
 # sudo -u odoo psql DATABASE

 ## some common issues:
 ## https://www.odoo.com/forum/help-1/question/dataerror-new-encoding-utf8-is-incompatible-with-the-encoding-of-the-template-database-sql-ascii-52124
 
 
