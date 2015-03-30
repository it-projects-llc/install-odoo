 #### Check does system use upstart
echo '' && whereis upstart | grep -q 'upstart: /' && echo 'You can use UPSTART' || echo 'There is no upstart in your system. Use SUPERVISORCTL instead'

 #### CHECK AND UPDATE LANGUAGE
 env | grep LANG

 export LANG=en_US.UTF-8
 export LANGUAGE=en_US.UTF-8
 dpkg-reconfigure locales


 #### DOWNLOADS...

 ### PACKAGES
apt-get update && \
apt-get upgrade -y && \
apt-get install -y git python-pip htop postgresql sudo moreutils tree && \
apt-get install -y emacs23-nox && \
whereis upstart | grep -q 'upstart: /' || apt-get install supervisor # install supervisor if there is upstart
 
 ## pip
 pip install psycogreen
 pip install rotate-backups

 ### SOURCE
 mkdir /usr/local/src/odoo-addons -p
 cd /usr/local/src/odoo-addons/

 git clone https://github.com/odoo-russia/odoo-russia.git &&\
 git clone https://github.com/yelizariev/pos-addons.git &&\
 git clone https://github.com/yelizariev/addons-yelizariev.git &&\
 git clone https://github.com/OCA/web.git &&\
 cd /usr/local/src/ &&\
 git clone https://github.com/odoo/odoo.git

 cd /usr/local/src/odoo-addons/
 mkdir addons-extra

 cd addons-extra
 ln -s ../odoo-russia/addons/l10n_ru/ .

 ### DEPS
 python --version # should be 2.7 or higher

 cd /usr/local/src/odoo
 echo "y" | (wget -q -O- https://raw.githubusercontent.com/odoo/odoo/master/odoo.py | python)
 #@@@@@@@@@@@@@@@@@@@@ NEED MANUAL WORK HERE (FIXME)


 ## wkhtmltopdf
 cd /usr/local/src
 lsb_release -a 
 uname -i
 # check version of your OS and download appropriate package
 # http://wkhtmltopdf.org/downloads.html
 # e.g.
 apt-get install xfonts-base xfonts-75dpi
 apt-get -f install
 wget http://downloads.sourceforge.net/project/wkhtmltopdf/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
 dpkg -i wkhtmltox-*.deb

 #@@@@@@@@@@@@@@@@@@@@ NEED MANUAL WORK HERE (FIXME)



#### DOWNLOADS done.


 ### SETTINGS
 ## gist url --  update it if you've forked this gist
export GIST="yelizariev/2abdd91d00dddc4e4fa4"

 ## from http://stackoverflow.com/questions/2914220/bash-templating-how-to-build-configuration-files-from-templates-with-bash
export PERL_UPDATE_ENV="perl -p -e 's/\{\{([^}]+)\}\}/defined \$ENV{\$1} ? \$ENV{\$1} : \$&/eg' "

export ODOO_DOMAIN=EDIT-ME.example.com
export ODOO_DATABASE=DATABASE_EDIT_ME

 export ODOO_USER=odoo

 export ODOO_BRANCH=8.0

 export ODOO_PASS=`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32};echo;`

 adduser --system --home=/opt/${ODOO_USER} --group ${ODOO_USER}

 # psql --version
 # pg_createcluster 9.3 main --start
 sudo -iu postgres  createuser -s ${ODOO_USER}

 ### BRANCH
 cd /usr/local/src/odoo

 git checkout -b ${ODOO_BRANCH} origin/${ODOO_BRANCH} 


 ### CONFIGS

 ## /var/log/odoo/
 mkdir /var/log/odoo/
 chown ${ODOO_USER}:${ODOO_USER} /var/log/odoo

 ## /etc/odoo/odoo-server.conf
 mkdir /etc/odoo
 cd /etc/odoo/

 wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-server.conf -O odoo-server.conf
 eval "${PERL_UPDATE_ENV} < odoo-server.conf" | sponge odoo-server.conf
 
 chown ${ODOO_USER}:${ODOO_USER} odoo-server.conf
 chmod 600 odoo-server.conf



 ### CONTROL SCRIPTS - upstart

 if whereis upstart | grep -q 'upstart: /' ###################################### IF
 then

 cd /etc/init/

 wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-init.conf -O odoo.conf
 eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf

 wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-longpolling-init.conf -O odoo-longpolling.conf
 eval "${PERL_UPDATE_ENV} < odoo-longpolling.conf" | sponge odoo-longpolling.conf


 ### START - upstart

 start odoo
 start odoo-longpolling

 ### CONTROL SCRIPTS - supervisor
 else ###################################################### ELSE

 cd /etc/supervisor/conf.d/

 wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-supervisor.conf -O odoo.conf
 eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf

 wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-longpolling-supervisor.conf -O odoo-longpolling.conf
 eval "${PERL_UPDATE_ENV} < odoo-longpolling.conf" | sponge odoo-longpolling.conf

 ### START - supervisor
supervisorctl reread
supervisorctl update

supervisorctl restart odoo
supervisorctl restart odoo-longpolling

 fi ####################################################   END IF


 ### CONTROL SCRIPTS - /etc/init.d/*
 # Such scripts are not recommended, because you will not get supervision features.
 # Use this link to find ones: https://gist.github.com/yelizariev/2abdd91d00dddc4e4fa4/d0ac3bd971e81213d17332647d9a74a580cfde6b
 

 ### BACKUP
 mkdir -p /opt/${ODOO_USER}/backups/
 chown ${ODOO_USER}:${ODOO_USER} /opt/${ODOO_USER}/backups/
 cd /usr/local/bin/
 wget -q https://gist.githubusercontent.com/${GIST}/raw/odoo-backup.py -O odoo-backup.py
 chmod +x odoo-backup.py
 echo -e "#6 6\t* * *\t${ODOO_USER} odoo-backup.py -d ${ODOO_DATABASE} -p /opt/${ODOO_USER}/backups/ --no-save-filestore --daily 8 --weekly 0 --monthly 0 --yearly 0" >> /etc/crontab
 echo -e "#4 4\t* * 7\t${ODOO_USER} odoo-backup.py -d ${ODOO_DATABASE} -p /opt/${ODOO_USER}/backups/" >> /etc/crontab
 ## to test run:
 # sudo su - ${ODOO_USER} -s /bin/bash -c  "odoo-backup.py -d ${ODOO_DATABASE} -p /opt/${ODOO_USER}/backups/"

 ### NGINX
 /etc/init.d/apache2 stop
 apt-get remove apache2 -y
 apt-get install nginx -y

 cd /etc/nginx && \
 wget -q https://gist.githubusercontent.com/${GIST}/raw/nginx_odoo_params -O odoo_params && \
 eval "${PERL_UPDATE_ENV} < odoo_params" | sponge odoo_params

 cd /etc/nginx/sites-available/ && \
 wget -q https://gist.githubusercontent.com/${GIST}/raw/nginx_odoo.conf -O odoo.conf && \
 eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf

 cd /etc/nginx/sites-enabled/ && \
 rm default && \
 ln -s ../sites-available/odoo.conf odoo.conf 
 
service nginx restart

 ### DEBUG

 ## show settings (admin password, addons path)
head /etc/odoo/odoo-server.conf 
 
 ## show odoo version
 grep '^version_info ' /usr/local/src/odoo/openerp/release.py 

 ## log
tail -f -n 100 /var/log/odoo/odoo-server.log 

 ## start from console (for ODOO_USER=odoo): 
 #  sudo su - odoo -s /bin/bash -c  "/usr/local/src/odoo/openerp-server -c /etc/odoo/odoo-server.conf"

 ## psql (use name of your database)
 # sudo -u odoo psql DATABASE

 ## some common issues:
 ## https://www.odoo.com/forum/help-1/question/dataerror-new-encoding-utf8-is-incompatible-with-the-encoding-of-the-template-database-sql-ascii-52124