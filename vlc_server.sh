#!/bin/sh -e
#
# ttnet pppoe setup script
#
CUR_DIR=`pwd`
DEF_MEDIA_DIR="/home/sd5/media"
STREAM_MEDIA=

#check shell script argument
if [ "$#" -ne 3 ]; then
        echo "Usage: $0 {stream file} {stream IPv4 address} {stream port}";
        exit 1;
fi

if  expr "$2" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
	echo "Stream IP:$2"
else
	echo "fail Stream IP";exit 1;
fi

if  expr "$3" : '[0-9]*$' >/dev/null; then
        echo "Port:$3"
else
        echo "fail Port";exit 1;
fi

#check input file
if [ -f "$1" ]; then
#	vlc -vvv $1 --sout udp:$2:$3 --loop --ttl 12 >/dev/null 2>&1
	STREAM_MEDIA=$1
elif [ -f "./$1" ]; then
#        vlc -vvv ./$1 --sout udp:$2:$3 --loop --ttl 12 >/dev/null 2>&1
	STREAM_MEDIA=./$1
elif [ -f "${DEF_MEDIA_DIR}/$1" ]; then
#	vlc -vvv ${CUR_DIR}/$1 --sout udp:$2:$3 --loop --ttl 12 >/dev/null 2>&1
	STREAM_MEDIA=${DEF_MEDIA_DIR}/$1
else
	echo "No Media Found!!!!";exit 1;
fi


echo "Starting VLC Stream: \"vlc -vvv ${STREAM_MEDIA} --sout udp:$2:$3 --loop --ttl 12\""
vlc -vvv ${STREAM_MEDIA} --sout udp:$2:$3 --loop --ttl 12 >/dev/null 2>&1
