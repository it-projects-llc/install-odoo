# install-odoo

Usage
-----

    # download install script
    wget https://raw.githubusercontent.com/iledarn/install-odoo/master/install-odoo-saas.sh -O install-odoo.sh

    # set parameters
    export ODOO_SAAS_TOOL="yes"

    # you have the following parameters to set (their default values after comma)
    ## Github script's repo
    SCRIPT_BRANCH, "yelizariev/install-odoo/master"
    ## E-Mail
    EMAIL_SERVER, stmp.example.com
    EMAIL_USER, mail@example.com 
    EMAIL_PASS, GiveMeYourPassBaby
    ## PostgreSQL
    DB_PASS, [generated]
    ## Odoo
    ODOO_DOMAIN, odoo.example.com
    ODOO_DATABASE, odoo.example.com
    ODOO_USER, odoo
    ODOO_BRANCH, 8.0
    ODOO_PASS, [generated]
    ## SSL
    SSL_CERT, /etc/ssl/certs/XXXX.crt
    SSL_KEY, /etc/ssl/private/XXXX.key
    ## DB Backup
    #set "no" if you don't want to configure backup
    DB_BACKUP, "yes"
    ## Odoo SaaS
    #set "yes" if you do want odoo saas tool
    ODOO_SAAS_TOOL, "no"
    SAAS_SERVER, server-1
    SAAS_TEMPLATE, template-1
    ## user /etc/hosts instead of dns server for saas
    #set "no" if you have dns server with odoo.example.com, server-1.odoo.example.com, template-1.odoo.example.com records
    SAAS_ADD_HOSTS, "yes"
    ## Add your private Git
    #Set to "yes", if you want to clone a private Git
    USE_PRIVATE_GIT, "no"
    #remote adress of your private Git
    PRIVATE_GIT_REMOTE, "https://MY_USER_NAME:MY_PASSWORD@bitbucket.org/MY_REMOTE_USER/MY_REMOTE_REPOSITORY.git"
    #local folder of your private Git 
    PRIVATE_GIT_LOCAL, "/usr/local/src/odoo-addons/MY_LOCAL_ADDON_FOLDER"

    # execute script with debugging
    /bin/bash -x install-odoo.sh

# Contributors

* [@yelizariev](https://github.com/yelizariev) - original semi-automated [script](https://gist.github.com/yelizariev/2abdd91d00dddc4e4fa4) for odoo installation
* [@bassn](https://github.com/bassn) - fully auto-automated [script](https://gist.github.com/bassn/996f8b168f0b1406dd54) for odoo installation
