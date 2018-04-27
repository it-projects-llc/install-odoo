=====
 Dev
=====

* extra packages to run tests
* `wdb <https://github.com/Kozea/wdb>`__ support. 
  How to use:

  * Add port exposing to your docker run command::
  
    -p 1984:1984
    
  * Past code below where you need a breakpoint::

     import wdb; wdb.set_trace()

  * Open http://localhost:1984/
