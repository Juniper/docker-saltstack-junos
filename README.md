
# SaltStack Docker Container for Junos

This project has been designed to help you get started easily with SaltStack on Junos.
In this project you'll find:
- **A docker container** with all SaltStack and all Junos Libraries
- **Make script** to easily start the docker container
- **A SaltStack Engine** to collect Syslog from Junos and convert them into Events in SaltStack

# Known Issues

- **urllib3\util\ssl_.py - 'SNIMissingWarning, InsecurePlatform' Warnings:** Solution is to upgrade Python from 2.7.6 to 2.7.9 or ```pip install pyOpenSSL ndg-httpsclient pyasn1```. Please note it does not effect salt-master, salt-minion or salt-proxy, in their functionality. 

# Getting Started with Salt on Docker
## 1- Define Junos device

Define each Junos device in a pillar file in the `pillar/` directory with `<devicename>.sls`

```yaml
# pillar/dev02.sls
proxy:
  proxytype: junos
  host: <ip>
  username: <login>
  passwd: <password>
```

All devices needs to be define as well in the `pillar/top.sls`
```yaml
base:
  dev01:
    - dev01
  dev02:
    - dev02
```

## 2- Start main container running Salt Master

```
make master-start
```

## 3- Start one container running Salt Proxy for each device

```
make proxy-start DEVICE=dev01
make proxy-start DEVICE=dev02
```
> you need one container for each device you want to add

### Directories mapping
The file `docker/salt_proxy.yaml` is automatically mapped to `/etc/salt/proxy`

## 4- Accept Proxy Keys on Master

Once your proxy are running you should see them in the list of `Unaccepted Keys` on the master

You can check the list of keys using:
```
make master-keys
```

To accept the keys, you need to go inside the container and run `salt-key -A`

Go in shell inside the container
```
make master-shell
```

Accept all keys
```
root@master> salt-key -A

The following keys are going to be accepted:
Unaccepted Keys:
dev01
dev02
Proceed? [n/Y] Y
Key for minion minion accepted.
```

### Optional

You can accept all keys at once:
```
make accept-keys
```

## 5- Verify

Check that all containers are running
```
docker ps
```

# Deeper understanding of the Makefile
 
The makefile in this project is used to, start and clean, any number of containers of salt-minion's and salt-proxies. This allows the user easier manage, operate and configure SaltStack topologies. It combines SaltStack requirements with Container flexibility.  

## Makefile features:
- Automatically start-up a container of master/minion/proxy with necessary attached configuration.
- Automatically clean-up specific/all containers of minions/proxies.

## Makefile limitations:
- Assumes GNU make.
- Not enough testing done on other platforms. 

## Overview of Commands

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

**Directories mapping** 
The local directory `pillar`, `engine` & `reactor` are automatically mapped to the
internal directory `/srv/pillar`, `/srv/engine` and `/srv/reactor`.

The file `docker/salt_master.yaml` is automatically mapped to `/etc/salt/master`.

**Port redirect**
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

**Note** 
Not recommended when security policies are enforced (e.g. not all minions shall speak to the master) 

#### Stop and remove Salt Master Container

To stop and remove a salt-master deamon container: 
```
make master-clean
```

**Note** 
Attached volumes (e.g. /srv/pillar, /srv/engine, etc.) and files (e.g. docker/salt_master.yaml, etc.) are not deleted. 

### Salt Minion make commands
#### Start a minion Docker container

Spins-up a salt-minion deamon in a docker container
```
make minion-start 
```
or
```
make minion-start DEVICE="<name>"
```

```<name>``` can be e.g. ```minion01```

**Note**
DEVICE allocates a name to Docker container. 
This can be seen via ```docker ps``` under the host machine. 

If DEVICE is used, the salt-minion will use this name to register to the salt-master.
IF DEVICE is NOT used, the salt-minion will use its container-id (which is its hostname) to register to the salt-master.

For easier troubleshooting, it is recommended to use and define DEVICE.

**Directories mapping** 
The file `docker/salt_minion.yaml` is automatically mapped to `/etc/salt/minion`.

### Salt Proxy make commands
#### Start a proxy Docker container

Spins-up a salt-proxy docker container (via docker run).
```
make proxy-start DEVICE="<name>"
```

```<name>``` can be e.g. ```proxy01```

**Note**
DEVICE allocates a name to the Docker container & proxy-id.

Other then salt-minion, salt-proxy needs a name aka proxy-id.
You do not have the option to spin-up a proxy without a name.

**Important**
The proxy with given name must have:
- A file defined under ```pillar/<name>.sls```
- A entry defined under ```pillar/top.sls```

Without, salt-proxy deamon will not work.

**Directories mapping** 
The local directory `pillar` is automatically mapped to the internal directory `/srv/pillar`.

The file `docker/salt_proxy.yaml` is automatically mapped to `/etc/salt/proxy`.

# Operation 

Useful tips/tricks commands

## Go inside main container and run junos.ping

Ping Junos devices

```
make master-shell
salt '*' junos.ping
```

## Engine - Junos Syslog

An engine that listen to syslog message from Junos devices,
extract event information and generate message on SaltStack bus.

Example of configuration
```yaml
  engines:
    - junos_syslog:
        port: 516
```

### Dependencies
```
pip install pyparsing twisted
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

## Create the docker container yourself

```
make build
```
