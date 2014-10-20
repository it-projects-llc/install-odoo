 #### DOWNLOADS...

 ### PACKAGES
apt-get update
apt-get upgrade -y
apt-get install -y git python-pip htop postgresql sudo moreutils
apt-get install -y emacs23-nox

 ### SOURCE
 cd /usr/local/src/

 ## tterp - russian localization
 git clone https://github.com/tterp/openerp.git tterp &&\
 git clone https://github.com/yelizariev/pos-addons.git &&\
 git clone https://github.com/yelizariev/addons-yelizariev.git &&\
 git clone https://github.com/odoo/odoo.git

 mkdir addons-extra
 ln -s /usr/local/src/tterp/modules/l10n_ru/ /usr/local/src/addons-extra/

 ### DEPS
 python --version # should be 2.7 or higher

 cd /usr/local/src/odoo
 echo "y" | wget -O- https://raw.githubusercontent.com/odoo/odoo/master/odoo.py | python

 ## wkhtmltopdf
 # http://wkhtmltopdf.org/downloads.html
 cd /usr/local/src
 wget http://downloads.sourceforge.net/project/wkhtmltopdf/0.12.1/wkhtmltox-0.12.1_linux-wheezy-amd64.deb
 dpkg -i wkhtmltox-*.deb

 ## Werkzeug
 # apt-get install python-pip -y
 # pip install Werkzeug --upgrade

 ## psycogreen
 pip install psycogreen


#### DOWNLOADS done.


 ### SETTINGS
 ## gist url --  update it if you've forked this gist
export GIST="yelizariev/2abdd91d00dddc4e4fa4"

 ## from http://stackoverflow.com/questions/2914220/bash-templating-how-to-build-configuration-files-from-templates-with-bash
export PERL_UPDATE_ENV="perl -p -i -e 's/\{\{([^}]+)\}\}/defined \$ENV{\$1} ? \$ENV{\$1} : \$&/eg' "

export ODOO_DOMAIN=EDIT-ME.example.com

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

 wget https://gist.githubusercontent.com/${GIST}/raw/odoo-server.conf -O odoo-server.conf
 eval "${PERL_UPDATE_ENV} < odoo-server.conf" | sponge odoo-server.conf
 
 chown ${ODOO_USER}:${ODOO_USER} odoo-server.conf
 chmod 600 odoo-server.conf

 ## /etc/init/odoo*.conf
 cd /etc/init/

 wget https://gist.githubusercontent.com/${GIST}/raw/odoo-init.conf -O odoo.conf
 eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf

 wget https://gist.githubusercontent.com/${GIST}/raw/odoo-longpolling-init.conf -O odoo-longpolling.conf
 eval "${PERL_UPDATE_ENV} < odoo-longpolling.conf" | sponge odoo-longpolling.conf


 ### START
start odoo
start odoo-longpolling


 ### NGINX
 apt-get remove apache2 -y
 apt-get install nginx -y

 cd /etc/nginx
 wget https://gist.githubusercontent.com/${GIST}/raw/nginx_odoo_params -O odoo_params
 #eval "${PERL_UPDATE_ENV} < odoo_params" | sponge odoo_params

 cd /etc/nginx/sites-available/
 wget https://gist.githubusercontent.com/${GIST}/raw/nginx_odoo.conf -O odoo.conf
 eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf

 cd /etc/nginx/sites-enabled/
 rm default
 ln -s ../sites-available/odoo.conf odoo.conf 
 
service nginx restart

 ### DEBUG

 ## show settings (admin password, addons path)
head /etc/odoo/odoo-server.conf 
 
 ## show odoo version
 grep 'version_info ' /usr/local/src/odoo/openerp/release.py 

 ## log
tail -f -n 100 /var/log/odoo/odoo-server.log 

 ## start from console: 
 #  sudo su - ${ODOO_USER} -s /bin/bash -c  "/usr/local/src/odoo/openerp-server -c /etc/odoo/odoo-server.conf"

 ## psql
 # sudo -u odoo psql DATABASE
