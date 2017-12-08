PosBox Docker
=============

Use it for development purpose only.

To run this docker you to provide `access to USB devices <https://stackoverflow.com/questions/24225647/docker-any-way-to-give-access-to-host-usb-or-serial-device>`_ of host machine, e.g.::

  # create postgres container
  docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db-posbox-11.0 postgres:9.5

  docker run \
  # expose ports:
  -p 9069:8069 \
  # remove container after stopping:
  --rm \
  # access to usb:
  --privileged \
  -v /dev/bus/usb:/dev/bus/usb
  # link to postgres
  --link db-posbox-11.0:db \
  # image name
  -t itprojectsllc/install-odoo:11.0-posbox


