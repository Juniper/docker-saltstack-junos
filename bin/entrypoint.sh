#!/bin/bash


if [ "$#" -ge 1 ]; then
	if [ "$1" == "salt-master" ]; then
   		eval "python /etc/salt/bin/startup.py"   
	fi
	eval $*
fi

exit 0 
