# Use-Case - Engine Event Triggering

The idea: 
- To show how SaltStack can receive Syslog messages from Junos and convert them into events for SaltStack

Example shown here:
- Monitor `UI_COMMIT_COMPLETED` Syslog message and check if anyone can still connect to the device.

The problem which it solves:
- Be able to check, if a device is still reachable after commit, can help e.g. to pin-point a mis-configuration

The components used for the example:
- Custom Syslog engine for SaltStack called `junos_syslog.py` programmed by Nitin Kumar
- `salt-master` called `satlmaster-engine` having the Syslog engine running.
- `salt-proxy` called `proxy01` connecting to a Junos device.
- a vMX with IP 172.17.254.1 which sends Syslog messages to the SaltStack engine.
- (optional) if vMX cannot be used then `salt-call` can be used to simulate the event on the bus. Please refer to [salt-call](#salt-call) section.

## Spin-up the use-case

**All commands must be executed under main directory (cd ..)**

### 0- Get/build image

Get the image via docker hub:
```
docker pull juniper/saltstack
```

or build your own image from git:
```
make build
```

### 1- Define Junos device

Define Junos device in the pillar file `proxy01.sls` in the `pillar/` directory.

```yaml
# pillar/proxy01.sls
proxy:
  proxytype: junos
  host: <ip>
  username: <login>
  passwd: <password>
```

This device is also defined under `pillar/top.sls`
```yaml
# pillar/top.sls
base:
  proxy01:
    - proxy01
```

### 2- Start use-case

To start the use-case:
```
make start-uc-engine
``` 

Which is the same as:
```
make master-start UC='engine'
make proxy-start DEVICE='proxy01' UC='engine'
(wait X seconds until proxy starts)
make accept-keys UC='engine'
```

### 3- Connect to Salt Master and Proxy

Connect to the master:
```
make master-shell UC='engine'
```

Connect to the proxy:
```
make proxy-shell DEVICE='proxy01' UC='engine'
```

### 4- Configure Junos device to send Syslog to the Salt Master

Check IP of Salt Master
```
# In the saltmaster-engine shell use:
ifconfig eth0
```

```
#ssh <ip-junos>

root@vmx> configure
root@vmx# set system syslog host <saltmaster-engine-eth0> 
root@vmx# commit 

```

**Optional**

We expose the Syslog port 516 of saltmaster-engine to the host operation system on port 8516.

If Junos device is therefore not in the same subnet as the docker containers (routed environment), then a configuration on port 8516 destination IP of the server hosting the docker can be used.

``` 
#ssh <ip-junos>

root@vmx> configure
root@vmx# set system syslog host <server-hosting-docker-containers-ip> port 8516  
root@vmx# commit 
```

### 5- Trigger event

Two options exist, configure anything on the Junos device and commit or use a `salt-call`.

For the latter, please refer to [salt-call](#salt-call).

### 6 - Result

See here [the events triggered under Salt Master](#result)


### Under the hood

- A reactor is configured under `/etc/salt/master.d/reactor.conf`
- The engine is configured under `/etc/salt/master`
- As soon as `UI_COMMIT_COMPLETED` is received from proxy01 (`jnpr/event/proxy01/UI_COMMIT_COMPLETED`) the reactor reacts and executes a sls under `/srv/reactor/` in our case defined as `junos.sls`
- When `junos.sls` is used by SaltStack, it tries to connect to Junos device via proxy01 (defined under `/srv/pillar/proxy01.sls` and `/srv/pillar/top.sls`) and executes the command `show version` on the device.
- if successful the [result](#result) can be seen.

## <a id='salt-call'></a>When using salt-call

Salt-call must summon a salt-minion on the saltmaster-engine, to send and process that event.

Prerequisite steps are therefore need to be done, to make `salt-call` work:
- Edit `/etc/salt/minion` and replace `master: salt` with `master: saltmaster-engine`
- Restart the saltmaster-engine from host machine with `docker restart saltmaster-engine`
- Accept the minion key on the master with `salt-keys -yA`

Then this salt-call can be used test the event under saltmaster-engine:
```
salt-call event.send 'jnpr/event/proxy01/UI_COMMIT_COMPLETED' '{"host": "172.17.254.1", "data": {"severity": 4, "appname": "mgd", "timestamp": "2016-11-17 19:30:14", "hostname": "proxy01", "pid": "84", "priority": 188 }'
```

## <a id='result'></a>Result

When receiving an event, you should see something along those lines:

```
root@saltmaster-engine:/# salt-run state.event pretty=True

salt/auth	{
    "_stamp": "2016-11-19T13:47:17.040980",
    "act": "accept",
    "id": "saltmaster-engine",
    "pub": "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuTb+CQZJyNXGPYxYhFwW\nluMyVxVbu1aTmiu8PbKDuNaC8k6ikM8EagJR8IZGq1mZgvwv/JnP8sYillcmhauY\nCrSBJTu+heWlDvANIqA3097Vd8ATWkXBBQqRNCnDk3MFdVvlbrtUHPvX88tu7llr\nPiQ+QBjuoLihtFlhKweWxzTn8KG6dZwrsN74gQWJUeEiXZ1ySpm/yPmnr4Tjvqa/\nSjucDXnerkudN9MakamE+LblEeVofx8KfBTJ19q5dcKOKrTrUGy6mZeZZ4hNiwjv\nM/wRfMouWxCTTWfRe1sQOeBChv4V7LoZfFqSrxmN3qiFYGm5EvaK9oduIeWxkbYY\nuwIDAQAB\n-----END PUBLIC KEY-----",
    "result": true
}
jnpr/event/proxy01/UI_COMMIT_COMPLETED	{
    "_stamp": "2016-11-19T13:47:18.223069",
    "cmd": "_minion_event",
    "data": {
        "__pub_fun": "event.send",
        "__pub_jid": "20161119134718201438",
        "__pub_pid": 485,
        "__pub_tgt": "salt-call"
    },
    "id": "saltmaster-engine",
    "tag": "jnpr/event/proxy01/UI_COMMIT_COMPLETED"
}
salt/job/20161119134718233038/ret/saltmaster-engine	{
    "_stamp": "2016-11-19T13:47:18.237743",
    "arg": [
        "jnpr/event/proxy01/UI_COMMIT_COMPLETED",
        "{\"host\": \"172.17.254.1\", \"data\": {\"severity\": 4, \"appname\": \"mgd\", \"timestamp\": \"2016-11-11 20:40:44\", \"hostname\": \"proxy01\", \"pid\": \"1584\", \"priority\": 188 }"
    ],
    "cmd": "_return",
    "fun": "event.send",
    "fun_args": [
        "jnpr/event/proxy01/UI_COMMIT_COMPLETED",
        "{\"host\": \"172.17.254.1\", \"data\": {\"severity\": 4, \"appname\": \"mgd\", \"timestamp\": \"2016-11-11 20:40:44\", \"hostname\": \"proxy01\", \"pid\": \"1584\", \"priority\": 188 }"
    ],
    "id": "saltmaster-engine",
    "jid": "20161119134718233038",
    "retcode": 0,
    "return": true,
    "tgt": "saltmaster-engine",
    "tgt_type": "glob"
}
20161119134718270119	{
    "_stamp": "2016-11-19T13:47:18.271630",
    "minions": [
        "proxy01"
    ]
}
salt/job/20161119134718270119/new	{
    "_stamp": "2016-11-19T13:47:18.272168",
    "arg": [
        "show version"
    ],
    "fun": "junos.cli",
    "jid": "20161119134718270119",
    "minions": [
        "proxy01"
    ],
    "tgt": "proxy01",
    "tgt_type": "glob",
    "user": "root"
}
salt/auth	{
    "_stamp": "2016-11-19T13:47:18.292151",
    "act": "accept",
    "id": "proxy01",
    "pub": "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmphBubIpbPkRNSOXkRfi\nX3S2Yara8zOn/CNSzzpuxKD0ei2zTvpm9C+VzRjE/Xshc6k7iGvx2BkG+1wuHzLQ\noGSqvQV2eDcxXpdamt9Md5mDPW5/GhURbbTem9+Ag2D9+ZzDdj4UrWK2YQkDFaWA\nTmCJhtNSkIhJCSVMVgI2kqDEDKmH0bazGpfF/aWiDO8Cdk9FPfy0dkEKWLSMtzHG\nr6vbbFkjVrwcgjvLZTQvm/LfBSo+6EUc6Mo90bOIDkB9kNj3BDsD6uvcgukuhHgW\nfHZl4VO2GVj/7RhzHhIAN/Wk2V82bTp6OgOEYdK1X4Pf+51HHUVjqWQV1ycWD9dg\nMwIDAQAB\n-----END PUBLIC KEY-----",
    "result": true
}
salt/job/20161119134718270119/ret/proxy01	{
    "_stamp": "2016-11-19T13:47:18.699319",
    "cmd": "_return",
    "fun": "junos.cli",
    "fun_args": [
        "show version"
    ],
    "id": "proxy01",
    "jid": "20161119134718270119",
    "retcode": 0,
    "return": {
        "message": "\nHostname: vmx1\nModel: vmx\nJunos: 16.1R2.11\nJUNOS OS Kernel 64-bit  [20160919.337492_builder_stable_10]\nJUNOS OS libs [20160919.337492_builder_stable_10]\nJUNOS OS runtime [20160919.337492_builder_stable_10]\nJUNOS OS time zone information [20160919.337492_builder_stable_10]\nJUNOS network stack and utilities [20160921.062227_builder_junos_161_r2]\nJUNOS modules [20160921.062227_builder_junos_161_r2]\nJUNOS mx modules [20160921.062227_builder_junos_161_r2]\nJUNOS libs [20160921.062227_builder_junos_161_r2]\nJUNOS OS libs compat32 [20160919.337492_builder_stable_10]\nJUNOS OS 32-bit compatibility [20160919.337492_builder_stable_10]\nJUNOS libs compat32 [20160921.062227_builder_junos_161_r2]\nJUNOS runtime [20160921.062227_builder_junos_161_r2]\nJUNOS Packet Forwarding Engine Simulation Package [20160921.062227_builder_junos_161_r2]\nJUNOS py extensions [20160921.062227_builder_junos_161_r2]\nJUNOS py base [20160921.062227_builder_junos_161_r2]\nJUNOS OS vmguest [20160919.337492_builder_stable_10]\nJUNOS OS crypto [20160919.337492_builder_stable_10]\nJUNOS mx libs compat32 [20160921.062227_builder_junos_161_r2]\nJUNOS mx runtime [20160921.062227_builder_junos_161_r2]\nJUNOS common platform support [20160921.062227_builder_junos_161_r2]\nJUNOS mx libs [20160921.062227_builder_junos_161_r2]\nJUNOS Data Plane Crypto Support [20160921.062227_builder_junos_161_r2]\nJUNOS mtx Data Plane Crypto Support [20160921.062227_builder_junos_161_r2]\nJUNOS daemons [20160921.062227_builder_junos_161_r2]\nJUNOS mx daemons [20160921.062227_builder_junos_161_r2]\nJUNOS Voice Services Container package [20160921.062227_builder_junos_161_r2]\nJUNOS Services TLB Service PIC package [20160921.062227_builder_junos_161_r2]\nJUNOS Services SSL [20160921.062227_builder_junos_161_r2]\nJUNOS Services Stateful Firewall [20160921.062227_builder_junos_161_r2]\nJUNOS Services RPM [20160921.062227_builder_junos_161_r2]\nJUNOS Services PTSP Container package [20160921.062227_builder_junos_161_r2]\nJUNOS Services PCEF package [20160921.062227_builder_junos_161_r2]\nJUNOS Services NAT [20160921.062227_builder_junos_161_r2]\nJUNOS Services Mobile Subscriber Service Container package [20160921.062227_builder_junos_161_r2]\nJUNOS Services MobileNext Software package [20160921.062227_builder_junos_161_r2]\nJUNOS Services Logging Report Framework package [20160921.062227_builder_junos_161_r2]\nJUNOS Services LL-PDF Container package [20160921.062227_builder_junos_161_r2]\nJUNOS Services Jflow Container package [20160921.062227_builder_junos_161_r2]\nJUNOS Services Deep Packet Inspection package [20160921.062227_builder_junos_161_r2]\nJUNOS Services IPSec [20160921.062227_builder_junos_161_r2]\nJUNOS Services IDS [20160921.062227_builder_junos_161_r2]\nJUNOS IDP Services [20160921.062227_builder_junos_161_r2]\nJUNOS Services HTTP Content Management package [20160921.062227_builder_junos_161_r2]\nJUNOS Services Crypto [20160921.062227_builder_junos_161_r2]\nJUNOS Services Captive Portal and Content Delivery Container package [20160921.062227_builder_junos_161_r2]\nJUNOS Services COS [20160921.062227_builder_junos_161_r2]\nJUNOS Border Gateway Function package [20160921.062227_builder_junos_161_r2]\nJUNOS AppId Services [20160921.062227_builder_junos_161_r2]\nJUNOS Services Application Level Gateways [20160921.062227_builder_junos_161_r2]\nJUNOS Services AACL Container package [20160921.062227_builder_junos_161_r2]\nJUNOS Extension Toolkit [20160921.062227_builder_junos_161_r2]\nJUNOS Packet Forwarding Engine Support (M/T Common) [20160921.062227_builder_junos_161_r2]\nJUNOS Online Documentation [20160921.062227_builder_junos_161_r2]\nJUNOS FIPS mode utilities [20160921.062227_builder_junos_161_r2]\n",
        "out": true
    },
    "success": true
}
```
