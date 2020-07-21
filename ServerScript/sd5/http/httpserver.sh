

#/bin/sh -e
#
# ttnet pppoe setup script
#
#GENIE_ACS_BIN_DIR="/home/sd5/genieacs/dist/bin/"

start_http() {
	echo "start http server with port $1" >&2
	python -m SimpleHTTPServer $1 &
}

stop_http(){
	kill -9 `ps -ef | grep "python \-m SimpleHTTPServer" | awk '{print $2}'`
}

usage(){
	echo "Usage: $0 {start|stop|restart} {port}" >&2
}

if [ "$#" -ne 2 ]; then
	usage
	exit 1
fi

case "$1" in
  start)
	start_http $2
        ;;
  stop)
	stop_http
        ;;
  restart)
	stop_http
	start_http $2
        ;;
  *)
        usage
	RETVAL=1
esac


