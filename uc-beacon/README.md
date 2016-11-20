# Use-Case - Engine Event Triggering

The idea:
- To show how we monitor a Junos string within a file and convert it to an event.
  - Natively this not supported within SaltStack; thereby, included in this use-case a custom beacon module.

Example show here:
- Monitor `ERROR` on a salt-minion file called `/var/log/random.log` and upon receiving this `ERROR` from the minion on the master, master restarts the process and writes a file in `/tmp/random_process_restart.log`

The problem which it solves:
- Consider a topology where devices are getting provisioned based on a dynamic process e.g. ZTP. If one is able to monitor any log with any regex, one can detect a malfunction and restart the process e.g. for ZTP the DHCP server. 

The components used for the example:
- Custom beacon module for SaltStack called `log.py` programmed by Iddo Cohen.
- `salt-master` called `saltmaster-beacon` used to sync beacon configuration to minions.
- `salt-minion` called `minion01` having `/var/log/random.log`

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

### 1- Start use-case

To start the use-case:
```
make start-uc-beacon
```

Which is the same as:
```
make master-start UC='beacon'
make minion-start DEVICE='minion01' UC='beacon'
(wait X seconds until minion starts)
make accept-keys UC='beacon'
(wait X seconds until master registers minion)
(execute on the saltmaster-beacon this command 'salt "minion01" saltutil.sync_beacons')
docker restart minion01
```

### 2- Start minion-shell and test

To test the event handling, start the minion01 shell.
```
make minion-shell DEVICE='minion01' UC='beacon'
```

Within the shell, check content of `/var/log/random.log`: 
```
root@minion01:/# cat /var/log/random.log
Started daemon
```

Also check if `/tmp/random_process_restart.log` does not exists:
```
root@minion01:/tmp# ls -la
total 8
drwxrwxrwt  3 root root 4096 Nov 20 12:26 .
drwxr-xr-x 74 root root 4096 Nov 20 12:22 ..
```

Test the event by echoing ERROR message into random.log:
```
root@minion01:/# echo "Critical ERROR occured" >> /var/log/random.log
```

And check if the new file `/tmp/random_process_restart.log` with the content has been created:
```
root@minion01:/tmp# cat random_process_restart.log
Restarting random deamon because of error: Critical ERROR occured
``` 

### Under the hood
- At start-up (`make start-uc-beacon`):
  - A reactor is configured on the saltmaster-beacon under `/etc/salt/master.d/reactor.conf` which gets executed and calls a rule set under `/srv/reactor/monitor_message.sls` 
  - The customer beacon is put under `/srv/salt/_beacon/` on the saltmaster-beacon and syncronised to minion01 via `salt "minion01" saltutil.sync_beacons`
  - Because of ticket # the SaltStack minion `minion01` needs to be restarted. This is done via `docker restart minion01`
- At operation:
  - Under the `/srv/pillar/top.sls` on the saltmaster-beacon a beacon is defined under `/srv/pillar/log.sls`. This definition is the also syncronised to minion01, so the minion knows what needs to be done.
  - Within the `log.sls` there is a configuration specifying a regex which should be matched.
  - When a match has been found, the raw message is send to the reactor on the event-bus to the saltmaster-beacon, which in return executes `/srv/reactor/monitor_message.sls`


