# Copyright

Copyright 2016 Juniper Networks, Inc. All rights reserved.

Licensed under the Juniper Networks Script Software License (the "License"). 

You may not use this script file except in compliance with the License, which is located at http://www.juniper.net/support/legal/scriptlicense/

Unless required by applicable law or otherwise agreed to in writing by the parties, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

# Create the docker container

```
make build
```
> this step can take 10-15 min the first time

# Define Junos device

Define each device in a pillar file in the `pillar/` directory with `<devicename>.sls`

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

# Start Salt

## Start one container running Salt Master

```
make master-start
```

## Start one container running Salt Proxy for each device

```
make proxy-start DEVICE=dev01
make proxy-start DEVICE=dev02
```
> you need one container for each device you want to add

## Accept Proxy Keys on Master

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
