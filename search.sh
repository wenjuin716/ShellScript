#!/bin/bash
# Program:
#	Program shows the script name, parameters...
# History:
# 2015/07/16	VBird	First release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
#PATH=/home/wenjuinlin/bin
export PATH

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function usage(){
	echo "usage:"     # 加上 -n 可以不斷行繼續在同一行顯示
	echo -e "	${RED}search.sh${NC} ${GREEN}<saerch path> <search file name> <keyword>${NC}"
}

#echo "The script name is        ==> ${0}"
#echo "Total parameter number is ==> $#"
#if [ "$#" -eq 0]; then
#	usage;	# printf the shellscript uasge

#check the input parameter is available or not
if [ "$#" -ne 3 ]; then 
	echo "The number of parameter is not equal 3.  Stop here."
	usage;  # printf the shellscript uasge
	exit 0
fi

#check the input parameter is available or not
#[ "$#" -ne 3 ] && echo "The number of parameter is not equal 3.  Stop here." && exit 0
#echo "Your whole parameter is   ==> '$@'"
#echo "The 1st parameter         ==> ${1}"
#echo "The 2nd parameter         ==> ${2}"

find ${1} -name "${2}" -exec grep -H --color=auto "${3}" {} \;
