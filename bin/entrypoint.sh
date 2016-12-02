#!/bin/bash

async () {
    # Handle SIGTERM/SIGINT in Docker... https://github.com/docker-library/mysql/issues/47
    "$@" &
    pid="$!"
    trap "echo 'Stopping PID $pid'; kill -SIGTERM $pid" SIGINT SIGTERM

    while kill -0 $pid > /dev/null 2>&1; do
        wait
    done
}

if [ "$#" -ge 1 ]; then
	if [ "$1" == "salt-master" ]; then
   		async "/etc/salt/bin/startup.py"   
        fi
	async $@
fi

