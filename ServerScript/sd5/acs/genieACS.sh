#
#/bin/sh -e
#
# ttnet pppoe setup script
#
#GENIE_ACS_BIN_DIR="/home/sd5/genieacs/dist/bin/"

start() {
	#cd $(GENIE_ACS_BIN_DIR)
	/home/sd5/acs_server/genieacs/dist/bin/genieacs-cwmp &
	/home/sd5/acs_server/genieacs/dist/bin/genieacs-ui --ui-jwt-secret secret &
	#/home/sd5/acs_server/genieacs/dist/bin/genieacs-nbi &
	#/home/sd5/acs_server/genieacs/dist/bin/genieacs-fs &
}

start_new() {
	cd /home/sd5/GenieACS/genieacs/
	bin/genieacs-cwmp &
	bin/genieacs-nbi &
	bin/genieacs-fs &
	cd /home/sd5/GenieACS/genieacs/genieacs-gui/
	rails s &
}

stop_acs(){
	killall -9 node
}

case "$1" in
  start)
#	start
	start_new
        ;;
  stop)
	stop_acs
        ;;
  restart)
	stop_acs
#	start
	start_new
        ;;
  *)
        echo "Usage: $0 {start|stop|restart}" >&2
        RETVAL=1
esac


