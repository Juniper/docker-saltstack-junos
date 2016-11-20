# SaltStack Docker Containers for Junos

This project has been designed to help you to get started easily with SaltStack on Junos.
In this project you'll find:
- **A docker container** with all SaltStack and all Junos Libraries
- **Make script** to easily start, stop and clean any number of docker containers
- **A Use-Case with SaltStack Engine** to collect Syslog from Junos and convert them into Events in SaltStack
- **A Use-Case with SaltStack Beacon** to monitor a Junos string in a file and convert it into Event in SaltStack

# Contributer

- Damien Garros
- Iddo Cohen
- Nitin Kumar
- Stephen Steiner 

# Known Issues

- **urllib3\util\ssl_.py - 'SNIMissingWarning, InsecurePlatform' Warnings:** Solution is to upgrade Python from 2.7.6 to 2.7.9 or ```pip install pyOpenSSL ndg-httpsclient pyasn1```. Please note it does not effect salt-master, salt-minion or salt-proxy, in their functionality. 

# Host Platforms Tested:

- Ubuntu 14.04 - 16.04 

# Skipping reading

We believe to have the best possible understanding/knowledge, you should read all the documentation (in here and each use-case folder).

To save time, the minimum what you should read:
- The documentation applicable for your use-case.
- [Example make commands](#example).

# Deep-dive into the Makefile
 
The makefile in this project is used to, start and clean, any number of containers of salt-minion's and salt-proxies. This allows the user easier manage, operate and configure SaltStack topologies. It combines SaltStack requirements with Container flexibility.  

## Makefile features:

- Automatically start-up a container of master/minion/proxy with necessary attached configuration.
- Automatically clean-up specific/all containers of minions/proxies.

## Makefile limitations:

- Assumes GNU make.
- Not enough testing done on other platforms. 

## Overview of Commands

For all upcoming commands other then `make build`, the parameter `UC='<uc-case-name->'` can be used.

If not defined, then `make` falls under the `default` use-case.

For example:
```
make master-start UC='engine'
```
would spin up a master called saltmaster-engine for use-case `engine`

however if not used:
```
make master-start
```
then a default master called saltmaster-default would be spined up.

The same goes for cleaning:
```
make minion-clean UC='engine'
```
only the minions under the engine use-case are cleaned.


**Thereby for all none specific use-cases scenarios, use make without the `UC=...` parameter**

### Build image from Dockerfile with make

The container is available on Docker Hub but if you prefer to built it yourself.
```
make build
```

> this step can take 10-15 min the first time

### Salt Master make commands
#### Start a Salt Master Docker container

Spins-up a salt-master daemon within a docker container
```
make master-start
``` 

#####Directories mapping
The local directory `pillar`, `engine` & `reactor` are automatically mapped to the
internal directory `/srv/pillar`, `/srv/engine` and `/srv/reactor`.

The file `docker/salt_master.yaml` is automatically mapped to `/etc/salt/master`.

#####Port redirect
By default the port `8516/udp` is exposed for Syslog.

#### Accessing the Salt Master Docker shell

Access the salt-master shell to e.g. accept keys, debug, etc.
```
make master-shell
``` 

#### See keys of Salt Master 

List the keys which the salt-master daemon has accepted/unaccepted.
```
make master-keys
```

#### Accept all keys at the Salt Master Container

Other then accept all keys manually, one can accept all the keys once.
```
make accept-keys
```

#####Note 
Not recommended when security policies are enforced (e.g. not all minions shall speak to the master) 

#### Stop and remove Salt Master Container

To stop and remove a salt-master deamon container: 
```
make master-clean
```

#####Note 
Attached volumes (e.g. /srv/pillar, /srv/engine, etc.) and files (e.g. docker/salt_master.yaml, etc.) are not deleted. 

### Salt Minion make commands
#### Start a Salt Minion

Spins-up a salt-minion deamon in a docker container
```
make minion-start 
```
or
```
make minion-start DEVICE="<name>"
```

`<name>` can be e.g. `make minion-start DEVICE="minion01"`

######Note
`DEVICE` allocates a name to Docker container. 
This can be seen via `docker ps` under the host machine. 

If `DEVICE=<name>` is used, the salt-minion will use this name to register to the salt-master.

IF `DEVICE=<name>` is NOT used, the salt-minion will use its container-id (which is its hostname) to register to the salt-master.

For easier troubleshooting, it is recommended to use and define `DEVICE`.

**Directories mapping** 
The file `docker/salt_minion.yaml` is automatically mapped to `/etc/salt/minion`.

#### Stop & Remove a Salt Minion

Stops and removes salt-minion container or containers.
```
make minion-clean DEVICE="<name>"
``` 
or 
```
make minion-clean
```

`<name>` can be a name e.g.: `make minion-clean DEVICE="minion01"` or container-id e.g. `make minion-clean DEVICE="62839031920c"`

#####Note
`DEVICE` specifies the name of which container should be deleted. 

If `DEVICE=<name>` is used, the specific salt-minion container will be stopped and deleted.

If `DEVICE=<name>` is NOT used, all salt-minion container's are being stopped and deleted.

Attached volumes and files are not deleted. 


### Salt Proxy make commands
#### Start a proxy Docker container

Spins-up a salt-proxy docker container (via docker run).
```
make proxy-start DEVICE="<name>"
```

`<name>` can be e.g. `proxy01`

#####Note
`DEVICE` allocates a name to the Docker container & proxy-id.

Other then salt-minion, salt-proxy needs a name aka proxy-id.
You do not have the option to spin-up a proxy without a name.

#####Important
The proxy with given name must have:
- A file defined under `pillar/<name>.sls`
- A entry defined under `pillar/top.sls`

Without those defined, salt-proxy deamon will work.

#####Directories mapping 
The local directory `pillar` is automatically mapped to the internal directory `/srv/pillar`.

The file `docker/salt_proxy.yaml` is automatically mapped to `/etc/salt/proxy`.

#### Stop & Remove a Salt Proxy

Stops and removes salt-proxy container or containers.
```
make proxy-clean DEVICE="<name>"
``` 
or 
```
make proxy-clean
```

`<name>` can only be a name e.g.: `make minion-clean DEVICE="proxy01"`

#####Note
`DEVICE` specifies the name of which container should be deleted. 

If `DEVICE=<name>` is used, the specific salt-proxy container will be stopped and deleted.

If `DEVICE=<name>` is NOT used, all salt-proxy container's are being stopped and deleted.

Attached volumes and files are not deleted. 

###Clean-up everything

To clean the salt-master, all salt-minions and all salt-proxies
```
make clean
```

It is equivalent to:
```
make master-clean
make minion-clean
make proxy-clean
```

#<a id='example'></a>Example of make commands

```
#Spin a default master
make master-start 

#Start master-shell for default
make master-shell 

#Start master-shell of "Engine" use-case
maske master-shell UC="engine"

#Spin a minion with name "foo"
make minion-start DEVICE="foo"

#Spin a proxy with name "bar" within "Engine" use-case
make proxy-start DEVICE="bar" UC="engine"

#Spin a minion without name but within "Beacon" use-case
make minion-start UC="beacon"

#Start shell of proxy "bar"
make proxy-start DEVICE="bar" UC="engine"

#Clean-up the minion "foo"
make minion-clean DEVICE="foo"

#Clean-up the proxy "bar"
make proxy-clean DEVICE="bar" UC="engine"

#Clean all containers under "Engine" use-case
make clean UC="engine"

#Clean all containers under default use-case
make clean
```

# Operation - useful tips/tricks commands

## Go inside main container and run junos.ping

Ping Junos devices

```
make master-shell
salt '*' junos.ping
```
## Events on SaltStack
### Useful commands to experiment with Events
#### Listen to all events on the Salt Bus
```
salt-run state.event pretty=True
```

#### Generate an event manually
Useful when you need to test your reactor
```
salt-call event.send 'jnpr/event/dev01/UI_COMMIT_COMPLETED' '{"host": "172.17.0.1", "data": {"severity": 4, "appname": "mgd", "timestamp": "2016-11-11 20:40:44", "hostname": "dev01", "pid": "1584", "priority": 188 }'
```
