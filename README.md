# SaltStack Docker Containers for Junos

master: [![Build Status](https://travis-ci.org/Juniper/docker-saltstack-junos.svg?branch=master)](https://travis-ci.org/Juniper/docker-saltstack-junos) 
dev/features: [![Build Status](https://travis-ci.org/iddocohen/docker-saltstack-junos.svg?branch=master)](https://travis-ci.org/iddocohen/docker-saltstack-junos)

This project has been designed to help you to get started easily with SaltStack on Junos.
In this project you'll find:
- **A docker container** with all SaltStack and all Junos Libraries
- **Make script** to easily start, stop and clean any number of docker containers
- **A Use-Case with SaltStack Engine** to collect Syslog from Junos and convert them into Events in SaltStack
- **A Use-Case with SaltStack Beacon** to monitor a Junos string in a file and convert it into Event in SaltStack

# Table of Content
   * [SaltStack Docker Containers for Junos](#saltstack-docker-containers-for-junos)
   * [Getting Started / 'Hello World' with Engine](#getting-started--hello-world-with-engine)
      * [1- Define Proxies](#1--define-proxies)
      * [2- Start Salt Master, Engine and Proxies Automatically](#2--start-salt-master-engine-and-proxies-automatically)
      * [4- Access Salt Master Shell](#4--access-salt-master-shell)
      * [5- (optional) Verify Proxy is running](#5--optional-verify-proxy-is-running)
   * [Contributer](#contributer)
   * [Known Issues](#known-issues)

# More about:
   * [The Use Case Engine](uc-engine/README.md)
   * [The Use Case Beacon](uc-beacon/README.md)
   * [The Makefile](docs/MAKEFILE.md)
   * [Operation](docs/OPERATION.md)

# Getting Started / 'Hello World' with Engine

## 1- Define Proxies

Define `uc-engine/pillar/top.sls` for example: 

```bash
root@host# cat uc-engine/pillar/top.sls

base:
  proxy01:
    - proxy01
```

and associate  under `uc-engine/pillar/`:

```bash
root@host# cat uc-engine/pillar/proxy01.sls

proxy:
   proxytype: junos
   host: 172.17.254.1
   username: admin
   passwd: juniper1
```

## 2- Start Salt Master, Engine and Proxies Automatically 

Under the main directory execute:

```bash
root@host# make master-start
```

or

```bash
root@host# docker run -t-

*Note:* Proxies are getting automatically started within the Salt Master Engine


## 3- Verify

Verify that `saltmaster-engine` is running:

```bash
root@host# docker ps 
```

## 4- Access Salt Master Shell

```
root@host# make master-shell
```

## 5- (optional) Verify Proxy is running

Check if proxy01 is running under the saltmaster-engine
```
root@saltmaster-engine# ps -ef | grep proxy01
```

# Contributer

- Damien Garros
- Iddo Cohen
- Nitin Kumar
- Stephen Steiner 

# Known Issues

- **urllib3\util\ssl_.py - 'SNIMissingWarning, InsecurePlatform' Warnings:** Solution is to upgrade Python from 2.7.6 to 2.7.9 or ```pip install pyOpenSSL ndg-httpsclient pyasn1```. Please note it does not effect salt-master, salt-minion or salt-proxy, in their functionality. 
- **Currently netconf port 830 must be open on the Junos device** Solution is to ```set system services netconf ssh```. Please note an option for using port 22 is being added.


