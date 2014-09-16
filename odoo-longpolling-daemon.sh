#!/bin/sh
 
### BEGIN INIT INFO
# Provides:		odoo-server-longpolling
# Required-Start:	$remote_fs $syslog
# Required-Stop:	$remote_fs $syslog
# Should-Start:		$network
# Should-Stop:		$network
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
USER={{ODOO_USER}}
 
test -x ${DAEMON} || exit 0
 
set -e
 
do_start () {
    echo -n "Starting ${DESC}: "
    start-stop-daemon --start --quiet --pidfile /var/run/${NAME}.pid --chuid ${USER} --background --make-pidfile --exec ${DAEMON} -- --config=${CONFIG} --logfile=${LOGFILE}
    echo "${NAME}."
}
 
do_stop () {
    echo -n "Stopping ${DESC}: "
    start-stop-daemon --stop --quiet --pidfile /var/run/${NAME}.pid --oknodo
    echo "${NAME}."
}
 
case "${1}" in
    start)
        do_start
        ;;
 
    stop)
        do_stop
        ;;
 
    restart|force-reload)
        echo -n "Restarting ${DESC}: "
        do_stop
        sleep 1
        do_start
        ;;
 
    *)
        N=/etc/init.d/${NAME}
        echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac
 
exit 0
