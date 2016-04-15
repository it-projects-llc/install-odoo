# install-odoo

Usage
-----

    # specify branch you are going to use
    export SCRIPT_BRANCH = "yelizariev/install-odoo/master"

    # download install script
    wget https://raw.githubusercontent.com/${SCRIPT_BRANCH}/install-odoo-saas.sh -O install-odoo.sh

    # set parameters, e.g.
    export ODOO_SAAS_TOOL="yes"
    # (list of all parameters can be found at install-odoo.sh)

    # run script
    /bin/bash -x install-odoo.sh

# Contributors

* [@yelizariev](https://github.com/yelizariev) - original semi-automated [script](https://gist.github.com/yelizariev/2abdd91d00dddc4e4fa4) for odoo installation
* [@bassn](https://github.com/bassn) - fully auto-automated [script](https://gist.github.com/bassn/996f8b168f0b1406dd54) for odoo installation
