#!/bin/bash
#
#Prigram:
#	This shell script is show "Hello World!" in your screen
#History:
#	2016/05/19	WenJuin	
#
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~bin
export PATH

read -p "Enter your name:" name #read the name from user input
name=${name:-Users}	#check the input value, if null or "", replease to "User"
echo -e "\nHello World! ${name} \a \n"
exit 0
