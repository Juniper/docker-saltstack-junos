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
