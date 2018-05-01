SpigotMC / BungeeCord startscript

This is a script for start/stop/restart Bungeechord / SpigotMC

Put it into your BungeeCord / SpigotMC root directory and edit config files. 


Basically for SpigotMC I make a symlink (with .jar extension)to SpigotMC jar file, and enter the symlink name into servername.dat. So will be easy identify the servers when they are running.


Files:
   # These only for guys who too layy to type params
start.sh
start_debug.sh
stop.sh
restart.sh

   # Main script fo start top the server
server.sh

Help screen

Syntax: ./server.sh { start | stop | restart | debug | log [f|t] | chkconfig | help | ver }

Params:

start   Start server in background
stop    Stop background running server
restart Restart bacground running server
debug   Start server in foreground. May stop with crtl+c
log     Show full log of server
log t   Tail of log file ( last 40 lines )
log f   Tail of log file and follow changes. Start with last 40 lines. Stop with ctrl+c key.
chkconfig       Check your configuration
ver     Check script version, and latest release on Github
help    This screen


Config files:

These files editable by you.
srv_cfg_servercmd.dat           Your command for run your server.
                                CMDline will looks like this when you issue start: srv_cfg_servercmd.dat srv_cfg_servername.dat ...
                                check chkconfig param for exact cmdline!
                                Default value is: java -Xms1024m -Xmx1024m -Dfile.encoding=UTF-8 -jar
srv_cfg_servername.dat          Your server program (file)name without extension.
                                (e.g. MyServer) itt will start MyServer.jar and create MyServer.pid and MyServer.log
srv_cfg_serverparam.dat         Insert your parameters into this config file e.g. --noconsole
                                Warning!!! No parameters passing trough from this file for debug start!
                                CMDline will looks like this when you issue start: ...... srv_cfg_servername.dat srv_cfg_serverparam.dat
                                check chkconfig param for exact cmdline!
srv_cfg_stopsec.dat             Wait seconds for stop server before this script exit with warn you about dead process.
                                Only numbers in config file. (e.g 10) minimum is 5 second, default 15 second.
srv_cfg_loglines.dat            How many last lines show from log file.
                                Only numbers in config file. (e.g 40) minimum value is 5, default value is 40.