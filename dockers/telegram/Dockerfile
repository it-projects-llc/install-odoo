FROM itprojectsllc/install-odoo:10.0

USER root

# install dependencies
RUN pip install -U pip && \
    pip install -U requests && \
    pip install 'requests[security]' && \
    pip install pyTelegramBotAPI  && \
    pip install emoji && \
    apt-get install libffi-dev && \
    pip install pygal && \
    pip install "cairosvg<2.0.0" tinycss cssselect && \
    echo "telegram dependencies are installed"

# add telegram to server-wide modules
RUN sed -i -e "s/^\(server_wide_modules.*\)/\1,telegram/" $OPENERP_SERVER

USER odoo
