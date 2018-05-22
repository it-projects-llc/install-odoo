=====
 Dev
=====

* extra packages to run tests
* `wdb <https://github.com/Kozea/wdb>`__ support. 
  How to use:

  * Run wdb server docker:: 
  
     docker run -d -p 1984:1984 --name wdb xoes/wdb-server

  * Link your odoo docker to wdb server::
  
    --link wdb:wdb -e WDB_SOCKET_SERVER=wdb -e WDB_NO_BROWSER_AUTO_OPEN=True
    
  * Past code below where you need a breakpoint::

     import wdb; wdb.set_trace()

  * Open http://localhost:1984/
