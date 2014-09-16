 ### PACKAGES
apt-get update
apt-get upgrade
apt-get install -y git python-pip htop postgresql sudo moreutils
apt-get install -y emacs23-nox

 ### SETTINGS
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
 ## https://github.com/odoo/odoo/issues/283
 wget -O- https://raw.githubusercontent.com/odoo/odoo/master/odoo.py|sed s/simple/upstream/|python
 ## choose Y when prompted

 git checkout -b ${ODOO_BRANCH} origin/${ODOO_BRANCH} 

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


 ### CONFIGS

 ## /var/log/odoo/
 mkdir /var/log/odoo/
 chown ${ODOO_USER}:${ODOO_USER} /var/log/odoo

 ## /etc/odoo/odoo-server.conf
 mkdir /etc/odoo
 cd /etc/odoo/

 wget https://gist.githubusercontent.com/yelizariev/2abdd91d00dddc4e4fa4/raw/odoo-server.conf -O odoo-server.conf
 eval "${PERL_UPDATE_ENV} < odoo-server.conf" | sponge odoo-server.conf
 
 chown ${ODOO_USER}:${ODOO_USER} odoo-server.conf
 chmod 600 odoo-server.conf

 ## /etc/init.d/odoo
 cd /etc/init.d

 wget https://gist.githubusercontent.com/yelizariev/2abdd91d00dddc4e4fa4/raw/odoo-daemon.sh -O odoo
 eval "${PERL_UPDATE_ENV} < odoo" | sponge odoo

 ## /etc/init.d/odoo-longpolling
 cd /etc/init.d

 wget https://gist.githubusercontent.com/yelizariev/2abdd91d00dddc4e4fa4/raw/odoo-longpolling-daemon.sh -O odoo-longpolling
 eval "${PERL_UPDATE_ENV} < odoo-longpolling" | sponge odoo-longpolling

 cat <<EOF > /etc/init.d/odoo-longpolling

#!/bin/sh

### BEGIN INIT INFO
# Provides:		odoo-server-longpolling
# Required-Start:	\$remote_fs \$syslog
# Required-Stop:	\$remote_fs \$syslog
# Should-Start:		\$network
# Should-Stop:		\$network
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	Enterprise Resource Management software
# Description:		Open ERP is a complete ERP and CRM software.
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
DAEMON=/usr/local/src/odoo/openerp-gevent
NAME=odoo-server-longpolling
DESC=odoo-server-longpolling
CONFIG=/etc/odoo/odoo-server.conf
LOGFILE=/var/log/odoo/odoo-server-longpolling.log
USER=${ODOO_USER}

test -x \${DAEMON} || exit 0

set -e

do_start () {
    echo -n "Starting \${DESC}: "
    start-stop-daemon --start --quiet --pidfile /var/run/\${NAME}.pid --chuid \${USER} --background --make-pidfile --exec \${DAEMON} -- --config=\${CONFIG} --logfile=\${LOGFILE}
    echo "\${NAME}."
}

do_stop () {
    echo -n "Stopping \${DESC}: "
    start-stop-daemon --stop --quiet --pidfile /var/run/\${NAME}.pid --oknodo
    echo "\${NAME}."
}

case "\${1}" in
    start)
        do_start
        ;;

    stop)
        do_stop
        ;;

    restart|force-reload)
        echo -n "Restarting \${DESC}: "
        do_stop
        sleep 1
        do_start
        ;;

    *)
        N=/etc/init.d/\${NAME}
        echo "Usage: \${NAME} {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0

EOF
 ## EOF =====================================


 ### START
 chmod +x  /etc/init.d/odoo
 chmod +x  /etc/init.d/odoo-longpolling

 update-rc.d odoo defaults
 update-rc.d odoo-longpolling defaults

 /etc/init.d/odoo start
 /etc/init.d/odoo-longpolling start


 ### NGINX
 apt-get install nginx -y

 cat <<EOF > /etc/nginx/odoo_params
charset utf-8;
location = /favicon.ico {
    return 404;
}
# increase proxy buffer to handle some OpenERP web requests
proxy_buffers 16 64k;
proxy_buffer_size 128k;
proxy_set_header Host \$host;
proxy_set_header X-Real-IP       \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
#proxy_redirect http:// https://;  
proxy_read_timeout          600s;
client_max_body_size 100m;
EOF
 ## EOF =====================================

 cat <<EOF > /etc/nginx/sites-available/odoo.conf

 server {
        listen 80 default_server;
        server_name ${ODOO_DOMAIN};
        include odoo_params;

        location /longpolling {
            proxy_pass http://localhost:8072;
        }

        location / {
            proxy_pass http://localhost:8069;
        }
}
EOF
 ## EOF =====================================
 ln -s /etc/nginx/sites-available/odoo.conf /etc/nginx/sites-enabled/odoo.conf 

service nginx restart

 ### DEBUG
 ## log
 # tail -f -n 100 /var/log/odoo/odoo-server.log 

 ## start from console: 
 #  sudo su - ${ODOO_USER} -s /bin/bash -c  "/usr/local/src/odoo/openerp-server -c /etc/odoo/odoo-server.conf"
