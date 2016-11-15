
# SaltStack Docker Container for Junos

This project has been designed to help you get started easily with SaltStack on Junos.
In this project you'll find:
- **A docker container** with all SaltStack and all Junos Libraries
- **Make script** to easily start the docker container
- **A SaltStack Engine** to collect Syslog from Junos and convert them into Events in SaltStack

# Known Issues
- **urllib3\util\ssl_.py: SNIMissingWarning, InsecurePlatform Warning:** Solution is to upgrade Python from 2.7.6 to 2.7.9 or ```pip install pyOpenSSL ndg-httpsclient pyasn1```. Please note it does not effect salt-master, salt-minion or salt-proxy, in their functionality. 

# Get Started with Salt on Docker
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

**Directories mapping**
The local directory `pillar`, `engine` & `reactor` are automatically mapped to the
internal directory `/srv/pillar`, `/srv/engine` and `/srv/reactor`
The file `docker/salt_master.yaml` is automatically mapped to `/etc/salt/master`

#### Port Redirection

By default the port `8516/udp` is exposed for syslog

## 3- Start one container running Salt Proxy for each device

```
make proxy-start DEVICE=dev01
make proxy-start DEVICE=dev02
```
> you need one container for each device you want to add

**Directories mapping**
The file `docker/salt_proxy.yaml` is automatically mapped to `/etc/salt/proxy`

## 4- Accept Proxy Keys on Master

Once your proxy are running you should see them in the list of `Unaccepted Keys` on the master

YOu can check the list of keys using:
```
make master-keys
```

To accept the keys, you need to go inside the container and run `salt-key -A`

GO in shell inside the container
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

## 5- Verify

Check that all containers are running
```
docker ps
```

Ping Junos devices
```shell
# Go inside main container and run junos.ping
make master-shell
salt '*' junos.ping
```

# Engine - Junos Syslog

An engine that listen to syslog message from Junos devices,
extract event information and generate message on SaltStack bus.

Example of configuration
```yaml
  engines:
    - junos_syslog:
        port: 516
```

## Dependancies
```
pip install pyparsing twisted
```

# Events on SaltStack
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

# Create the docker container yourself

The container is available on Docker Hub but if you prefer to built it yourself.
```
make build
```
> this step can take 10-15 min the first time
