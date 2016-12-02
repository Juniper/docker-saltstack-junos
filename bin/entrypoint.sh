#!/bin/bash


pid=""


async () {
    "$@" &
    pid="$!"
    trap "echo 'Stopping PID $pid'; kill -SIGTERM $pid" SIGINT SIGTERM

    # A signal emitted while waiting will make the wait command return code > 128
    # Let's wrap it in a loop that doesn't end before the process is indeed stopped
    while kill -0 $pid > /dev/null 2>&1; do
        wait
    done
}

clean_up () {
   #while read -r pid; do
   #      kill -9 $pid
         #while kill -0 $pid > /dev/null 2>&1; do
         #    wait
         #done 
   #done </tmp/running
   #rm /tmp/running
   
   exit 0 
}

if [ "$#" -ge 1 ]; then
	if [ "$1" == "salt-master" ]; then
   		async "/etc/salt/bin/startup.py"   
        fi
	async $@
fi

