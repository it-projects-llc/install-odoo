Odoo remote development
=======================

This docker allows to run odoo and chromium remotely.

* Access to strong server resources
* Quick demonstration (e.g. http://module_name.odoo-10.developer_name.youcompany.example.com )
* Terminal sharing (via tmux)
* Pair programming (via tmux + emacs\vim)


Installation
============

Connect to your remote server

    docker run \
    -d \
    --link db-odoo:db \
    -p 1001:8069 \
    -p 1002:8072 \
    -p 1003:22 \
    --name odoo-dev \
    -t itprojectsllc/install-odoo:8.0-remote-dev


Configuration
=============

Adding ssh keys
---------------

To add initial ssh keys connect to the docker directly via ssh or via ``docker exec ... /bin/bash``. 

Then exec something like

     curl --silent https://github.com/yelizariev.keys >> /opt/odoo/.ssh/authorized_keys


Workflow
========

Connecting to remote environment
--------------------------------

    ssh -X odoo@YOUSERVER

Run odoo
--------

    /odoo.sh

All parameters are passed to odoo script, e.g.

    # install module "project" to database "test"
    /odoo.sh -d test -i project


Remote browser
--------------

To run chromium simply execute

     /chromium.sh

Shared emacs session
--------------------

connect to a docker an execute

    # run once
    /emacs-server.sh

    # run for every client
    /emacs-client.sh

Files sync
----------

A developer can edit files locally by using `lsyncd <https://github.com/axkibe/lsyncd>`:

    TODO

**lsyncd** provides automatic one-way sync, i.e. from local to remote. For opposite sync (from remote to local, e.g. after pair programming) run:

    # Upload files from remote. Make a backup of local files before using!
    TODO

