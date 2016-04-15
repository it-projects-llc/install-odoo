# install-odoo

Usage
-----

    # install and upgrade pip
    apt-get install python-pip
    pip install -U pip
    apt-get purge python-pip

    # download install script
    wget https://raw.githubusercontent.com/iledarn/install-odoo/master/install-odoo-saas.sh -O install-odoo.sh

    # set parameters
    export ODOO_SAAS_TOOL="yes"

    # execute script with debugging
    /bin/bash -x install-odoo.sh

# Contributors

* [@yelizariev](https://github.com/yelizariev) - original semi-automated [script](https://gist.github.com/yelizariev/2abdd91d00dddc4e4fa4) for odoo installation
* [@bassn](https://github.com/bassn) - fully auto-automated [script](https://gist.github.com/bassn/996f8b168f0b1406dd54) for odoo installation
