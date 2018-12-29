#!/bin/bash

ESCPOS=$ODOO_SOURCE_DIR/addons/hw_escpos/escpos
EXCEPTIONS_PY=$ESCPOS/exceptions.py

echo "

class NoBackendError(Error):
    def __init__(self, msg=\"\"):
        Error.__init__(self, msg)
        self.msg = msg
        self.resultcode = 101

    def __str__(self):
        return \"No USB Devices Found \" + str(self.msg)
" >> $EXCEPTIONS_PY

PRINTER_PY=$ESCPOS/printer.py

sed -i "s;\
self\.device\.send(msg);\
if type(msg) is str:\n\
            msg = msg.encode(\"utf-8\") \n\
        self\.device\.send(msg);" \
$PRINTER_PY

CONTROLLERS_PY=$ODOO_SOURCE_DIR/addons/hw_escpos/controllers/main.py

sed -i "s;\
printers = self\.connected_usb_devices();\
try:\n\
            printers = self.connected_usb_devices()\n\
        except:\n\
            printers = []\n\
            raise NoBackendError();" \
$CONTROLLERS_PY

sed -i "s;\
print(\"No device found %s\" % e);\
print(\"No device found %s\" % e)\n\
\n\
            except NoBackendError as e:\n\
                print(\"No USB device found %s\" % e)\n\
                time.sleep(5);" \
$CONTROLLERS_PY
