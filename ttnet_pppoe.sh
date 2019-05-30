#!/bin/sh -e
#
# ttnet pppoe setup script
#

case "$1" in
  start)
	pppoe-server -I enp2s5.35 -L 192.168.35.1 -R 192.168.35.100 -N 50
        ;;
  stop)
	killall pppoe-server
        ;;
  restart|reload|force-reload)
	killall pppoe-server
	pppoe-server -I enp2s5.35 -L 192.168.35.1 -R 192.168.35.100 -N 50
        ;;
  *)
        echo "Usage: $0 {start|stop|restart|reload|force-reload}" >&2
        RETVAL=1
esac

