SpigotMC / BungeeCord startscript

This is a script for start/stop/restart Bungeechord / SpigotMC

Put it into your BungeeCord / SpigotMC root directory and edit config files. 


Basically for SpigotMC I make a symlink to SpigotMC jar file, and enter the symlink name into servername.dat. So will be easy identify the servers when they are running.


Files:
   # These only for guys who too layy to type params
start.sh
start_debug.sh
stop.sh
restart.sh

   # Main script fo start top the server
server.sh

   # Config files
srv_cfg_servername.dat    # edit and insert your server jar filename without extension. only 1 server!
srv_cfg_stopsec.dat       # when stopping server how many secs wait for stop before script exit with error. Only numbers, the minimum is 5 sec, deafult 15
