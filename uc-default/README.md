# Use-Case - Getting Started with Salt on Docker

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

### 2- Start main container running Salt Master

```
make master-start
```

### 3- Start one container running Salt Proxy for each device

```
make proxy-start DEVICE=dev01
make proxy-start DEVICE=dev02
```
> you need one container for each device you want to add


### 4- Accept Proxy Keys on Master

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

#### (Optional) The lazy way:

You can accept all keys at once
```
make accept-keys
```

### 5- Verify

Check that all containers are running
```
docker ps
```


