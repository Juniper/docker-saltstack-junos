
# Example of make commands

## Spin a engine master

`make master-start` 

## Start master-shell for Engine Use-case

`make master-shell` 
same as:
`make master-shell UC="engine"`

## Spin a minion with name "foo" under Engine Use-Case

`make minion-start DEVICE="foo"`
same as:
`make master-start DEVICE="foo" UC="engine"` 

## Spin a minion without name but within Beacon Use-Case

`make minion-start UC="beacon"`

## Clean-up the minion with the name "foo" under Engine Use-Case

`make minion-clean DEVICE="foo"`

## Clean all containers under "Engine" use-case

`make clean`
same as:
`make clean UC="engine"`

# Deep-dive into the Makefile
 
The makefile in this project is used to, start and clean, any number of containers of salt-minion's and salt-proxies. This allows the user easier manage, operate and configure SaltStack topologies. It combines SaltStack requirements with Container flexibility.  

## Makefile features:

- Automatically start-up a container of master/minion/proxy with necessary attached configuration.
- Automatically clean-up specific/all containers of minions/proxies.

## Makefile limitations:

- Assumes GNU make.
- Not enough testing done on other platforms. 

## Overview of Commands

For all upcoming commands other then `make build`, the parameter `UC='<uc-case-name>'` can be used.

If not defined, then `make` falls under the `engine` use-case.

For example:
```
make master-start UC='beacon'
```
would spin up a master called saltmaster-beacon for use-case `beacon`

however if not used:
```
make master-start
```
then a `engine` master called saltmaster-engine would be spined up.

The same goes for cleaning:
```
make minion-clean UC='engine'
```
or 
```
make minion-clean
```
only the minions under the `engine` use-case are cleaned.


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

**Furthermore, if proxies are defined under `<uc-case>/pillar/` then those are spinned up as well.**

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

#### About Salt Keys 

All keys are getting accepted by the saltmaster automatically. No manuel accepting needed.

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

If `DEVICE=<name>` is NOT used, the salt-minion will use its container-id (which is its hostname) to register to the salt-master.

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

### Clean-up everything

To clean the salt-master and all salt-minions
```
make clean
```

It is equivalent to:
```
make master-clean
make minion-clean
```


