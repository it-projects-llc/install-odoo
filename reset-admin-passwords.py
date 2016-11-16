#!/usr/bin/python
# updates password for SUPERUSER_ID in all odoo databases

import contextlib
import os
import psycopg2
import datetime
import time


def log(*args):
    ts = datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
    print ''
    print ts
    print 'saas.py >>> ' + ', '.join([str(a) for a in args])


@contextlib.contextmanager
def local_pgadmin_cursor(dbname='postgres'):
    env = os.environ
    cnx = None
    try:
        cnx = psycopg2.connect(database=dbname,
                               user=env.get('PGUSER'),
                               password=env.get('PGPASSWORD'),
                               host=env.get('PGHOST'),
                               port=env.get('PGPORT'),
                               )
        cnx.autocommit = True  # required for admin commands
        yield cnx.cursor()
    finally:
        if cnx: cnx.close()


def get_db_list():
    """ simplified version of exp_list function from openerp/service/db.py"""
    env = os.environ
    db_user = env.get('PGUSER')
    templates_list = tuple(set(['template0', 'template1', 'postgres']))
    with local_pgadmin_cursor() as cr:
        cr.execute("select datname from pg_database where datdba=(select usesysid from pg_user where usename=%s) and datname not in %s order by datname", (db_user, templates_list))
        res = [name for (name,) in cr.fetchall()]

    return res


def update_admin_password(dbname, new_password):
    SUPERUSER_ID = 1
    with local_pgadmin_cursor(dbname) as cr:
        cr.execute("UPDATE res_users set password=%s WHERE id=%s", (new_password, SUPERUSER_ID,))


def main():
    new_password = os.environ.get('NEW_ADMIN_PASSWORD')
    if not new_password:
        exit(1)
    db_list = get_db_list()
    for dbname in db_list:
        try:
            update_admin_password(dbname, new_password)
            log('admin password is updated in %s' % dbname)
        except psycopg2.ProgrammingError, e:
            log('error on updating admin password in database %s' % dbname, e)


if __name__ == '__main__':
    main()
