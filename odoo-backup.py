#!/usr/bin/env python
### depends on https://github.com/xolox/python-rotate-backups -- check this url for understanding rotating parameters
import argparse

import os
import subprocess
import shutil
import zipfile
import datetime
import tempfile
from contextlib import contextmanager

### READ INPUT
parser = argparse.ArgumentParser(description='Odoo backup tool.')
parser.add_argument('-d', '--database', dest='database', nargs='+', help='database for backup')
parser.add_argument('--no-save-filestore', dest='save_filestore', action='store_false', help='skip filestore to save disk space')
parser.add_argument('--no-rotate', dest='rotate', action='store_false', help='skip backups rotating')
parser.add_argument('-p', '--path', dest='path', default='/tmp/', help='path to save backup')
parser.add_argument('-c', '--odoo-config', dest='odoo_config', default='/etc/odoo/odoo-server.conf', help='odoo config file')
parser.add_argument('--hourly', dest='hourly', default='24', help='how many hourly backups to preserve')
parser.add_argument('--daily', dest='daily', default='7', help='how many daily backups to preserve')
parser.add_argument('--weekly', dest='weekly', default='4', help='how many weekly backups to preserve')
parser.add_argument('--monthly', dest='monthly', default='12', help='how many monthly backups to preserve')
parser.add_argument('--yearly', dest='yearly', default='always', help='how many yearly backups to preserve')

#parser.add_argument('--odoo-source', dest='odoo_source', default='/usr/local/src/odoo/', help='odoo source dir')

args = parser.parse_args()

def get_odoo_config():
    import ConfigParser
    p = ConfigParser.ConfigParser()
    p.read(args.odoo_config)
    res = {}
    for (name,value) in p.items('options'):
        if value=='True' or value=='true':
            value = True
        if value=='False' or value=='false':
            value = False
        res[name] = value
    return res

odoo_config = get_odoo_config()


### EXECUTE

def exec_pg_environ():
    """
    Force the database PostgreSQL environment variables to the database
    configuration of Odoo.

    Note: On systems where pg_restore/pg_dump require an explicit password
    (i.e.  on Windows where TCP sockets are used), it is necessary to pass the
    postgres user password in the PGPASSWORD environment variable or in a
    special .pgpass file.

    See also http://www.postgresql.org/docs/8.4/static/libpq-envars.html
    """
    env = os.environ.copy()
    db_user = odoo_config.get('db_user') or os.getenv('DB_ENV_POSTGRES_USER')
    if db_user:
        env['PGUSER'] = db_user
    db_host = odoo_config.get('db_host') or os.getenv('DB_PORT_5432_TCP_ADDR')
    if db_host:
        env['PGHOST'] = db_host
    db_port = odoo_config.get('db_port') or os.getenv('DB_PORT_5432_TCP_PORT')
    if db_port:
        env['PGPORT'] = db_port

    db_password = odoo_config.get('db_password') or os.getenv('DB_ENV_POSTGRES_PASSWORD')
    if db_password:
        env['PGPASSWORD'] = db_password

    return env

def dump_sql(db, dump_file):
    cmd = ['pg_dump', '--format=p', '--no-owner', '--file=' + dump_file]

    cmd.append(db)

    if exec_pg_command(*cmd):
        print ' '.join(cmd)
        raise Exception("Couldn't dump database")

def backup(db, dump_dir):
    odoo_data_dir = odoo_config.get('data_dir', '~/.local/share/Odoo/')
    filestore = os.path.join(odoo_data_dir, 'filestore', db)
    if args.save_filestore:
        os.symlink(filestore, os.path.join(dump_dir, 'filestore'))

    dump_file = os.path.join(dump_dir, 'dump.sql')
    dump_sql(db, dump_file)

    dump_archive  = "%(db)s_%(timestamp)s_%(mark)s.dump" % {
        'db': db,
        'timestamp': datetime.datetime.utcnow().strftime("%Y-%m-%d_%H-%M-%SZ"),
        'mark': 'full' if args.save_filestore else 'quick',
    }
    with open(dump_archive, 'w') as stream:
        zip_dir(dump_dir, stream, include_dir=False)
    return dump_archive

def rotate(backup_dir):
    cmd = ['rotate-backups']
    for period in ('hourly', 'daily', 'weekly', 'monthly', 'yearly'):
        cmd.extend(['--%s' % period, getattr(args, period) ] )
    cmd.append(backup_dir)
    cmd.extend(['2>', '/dev/null'])
    os.system(' '.join(cmd))

def main():
    for db in args.database:
        backup_dir = os.path.join(args.path, db, 'full' if args.save_filestore else 'quick')
        if not os.path.exists(backup_dir):
            os.system('mkdir -p %s' % backup_dir)

        with tempdir() as dump_dir:
            dump_archive = backup(db, dump_dir)
            shutil.move(dump_archive, os.path.join(backup_dir, dump_archive))

        if args.rotate:
            rotate(backup_dir)

### TOOLS

def find_pg_tool(name):
    path = None
    #if config['pg_path'] and config['pg_path'] != 'None':
    #    path = config['pg_path']
    try:
        return which(name, path=path)
    except IOError:
        return None

def exec_pg_command(name, *args):
    prog = find_pg_tool(name)
    env = exec_pg_environ()
    if not prog:
        raise Exception('Couldn\'t find %s' % name)
    args2 = (prog,) + args

    with open(os.devnull) as dn:
        return subprocess.call(args2, stdout=dn, stderr=subprocess.STDOUT, env=env)

def zip_dir(path, stream, include_dir=True):      # TODO add ignore list
    path = os.path.normpath(path)
    len_prefix = len(os.path.dirname(path)) if include_dir else len(path)
    if len_prefix:
        len_prefix += 1

    with zipfile.ZipFile(stream, 'w', compression=zipfile.ZIP_DEFLATED, allowZip64=True) as zipf:
        for dirpath, dirnames, filenames in os.walk(path, followlinks=True):
            for fname in filenames:
                bname, ext = os.path.splitext(fname)
                ext = ext or bname
                if ext not in ['.pyc', '.pyo', '.swp', '.DS_Store']:
                    path = os.path.normpath(os.path.join(dirpath, fname))
                    if os.path.isfile(path):
                        zipf.write(path, path[len_prefix:])

@contextmanager
def tempdir():
    tmpdir = tempfile.mkdtemp()
    try:
        yield tmpdir
    finally:
        shutil.rmtree(tmpdir)

import sys
from os import access, defpath, pathsep, environ, F_OK, R_OK, W_OK, X_OK
from os.path import exists, dirname, split, join

windows = sys.platform.startswith('win')

defpath = environ.get('PATH', defpath).split(pathsep)

if windows:
    defpath.insert(0, '.') # can insert without checking, when duplicates are removed
    # given the quite usual mess in PATH on Windows, let's rather remove duplicates
    seen = set()
    defpath = [dir for dir in defpath if dir.lower() not in seen and not seen.add(dir.lower())]
    del seen

    defpathext = [''] + environ.get('PATHEXT',
        '.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC').lower().split(pathsep)
else:
    defpathext = ['']

def which_files(file, mode=F_OK | X_OK, path=None, pathext=None):
    """ Locate a file in a path supplied as a part of the file name,
        or the user's path, or a supplied path.
        The function yields full paths (not necessarily absolute paths),
        in which the given file name matches an existing file in a directory on the path.

        >>> def test_which(expected, *args, **argd):
        ...     result = list(which_files(*args, **argd))
        ...     assert result == expected, 'which_files: %s != %s' % (result, expected)
        ...
        ...     try:
        ...         result = [ which(*args, **argd) ]
        ...     except IOError:
        ...         result = []
        ...     assert result[:1] == expected[:1], 'which: %s != %s' % (result[:1], expected[:1])

        >>> if windows: cmd = environ['COMSPEC']
        >>> if windows: test_which([cmd], 'cmd')
        >>> if windows: test_which([cmd], 'cmd.exe')
        >>> if windows: test_which([cmd], 'cmd', path=dirname(cmd))
        >>> if windows: test_which([cmd], 'cmd', pathext='.exe')
        >>> if windows: test_which([cmd], cmd)
        >>> if windows: test_which([cmd], cmd, path='<nonexistent>')
        >>> if windows: test_which([cmd], cmd, pathext='<nonexistent>')
        >>> if windows: test_which([cmd], cmd[:-4])
        >>> if windows: test_which([cmd], cmd[:-4], path='<nonexistent>')

        >>> if windows: test_which([], 'cmd', path='<nonexistent>')
        >>> if windows: test_which([], 'cmd', pathext='<nonexistent>')
        >>> if windows: test_which([], '<nonexistent>/cmd')
        >>> if windows: test_which([], cmd[:-4], pathext='<nonexistent>')

        >>> if not windows: sh = '/bin/sh'
        >>> if not windows: test_which([sh], 'sh')
        >>> if not windows: test_which([sh], 'sh', path=dirname(sh))
        >>> if not windows: test_which([sh], 'sh', pathext='<nonexistent>')
        >>> if not windows: test_which([sh], sh)
        >>> if not windows: test_which([sh], sh, path='<nonexistent>')
        >>> if not windows: test_which([sh], sh, pathext='<nonexistent>')

        >>> if not windows: test_which([], 'sh', mode=W_OK)  # not running as root, are you?
        >>> if not windows: test_which([], 'sh', path='<nonexistent>')
        >>> if not windows: test_which([], '<nonexistent>/sh')
    """
    filepath, file = split(file)

    if filepath:
        path = (filepath,)
    elif path is None:
        path = defpath
    elif isinstance(path, str):
        path = path.split(pathsep)

    if pathext is None:
        pathext = defpathext
    elif isinstance(pathext, str):
        pathext = pathext.split(pathsep)

    if not '' in pathext:
        pathext.insert(0, '') # always check command without extension, even for custom pathext

    for dir in path:
        basepath = join(dir, file)
        for ext in pathext:
            fullpath = basepath + ext
            if exists(fullpath) and access(fullpath, mode):
                yield fullpath

def which(file, mode=F_OK | X_OK, path=None, pathext=None):
    """ Locate a file in a path supplied as a part of the file name,
        or the user's path, or a supplied path.
        The function returns full path (not necessarily absolute path),
        in which the given file name matches an existing file in a directory on the path,
        or raises IOError(errno.ENOENT).

        >>> # for doctest see which_files()
    """
    try:
        return iter(which_files(file, mode, path, pathext)).next()
    except StopIteration:
        try:
            from errno import ENOENT
        except ImportError:
            ENOENT = 2
        raise IOError(ENOENT, '%s not found' % (mode & X_OK and 'command' or 'file'), file)


if __name__ == '__main__':
    main()

