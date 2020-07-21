#!/bin/bash
#
# multicast streaming server script
#  Hint: it should run setup_multicast_static_rt.sh before streaming
#
CUR_DIR=`pwd`
DEF_MEDIA_DIR="/home/sd5/media"
STREAM_MEDIA=

regex="^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$"
IPV6_IP=0

#check shell script argument
if [ "$#" -ne 4 ]; then
        echo "Usage: $0 {stream file} {stream IPv4 address} {stream port} {output intf}";
        exit 1;
fi

if  expr "$2" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
	echo "Stream IP:$2"
else
	if [[ "$2" =~ $regex ]]; then
		echo "Stream IPv6:$2";
		IPV6_IP=1;
	else
		echo "fail Stream IP";exit 1;
	fi
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

if [ $IPV6_IP -eq 1 ]; then
	echo "ipv6 ip"
	echo "Starting VLC Stream: \"vlc -vvv ${STREAM_MEDIA} --sout udp:[$2]:$3 --loop --ttl 12\" on $4"
	vlc -vvv ${STREAM_MEDIA} --sout udp:[$2]:$3 --loop --ttl 12 --miface=$4 >/dev/null 2>&1
else
	echo "ipv4 ip"
	echo "Starting VLC Stream: \"vlc -vvv ${STREAM_MEDIA} --sout udp:$2:$3 --loop --ttl 12\" on $4"
	vlc -vvv ${STREAM_MEDIA} --sout udp:$2:$3 --loop --ttl 12 --miface=$4>/dev/null 2>&1
fi
