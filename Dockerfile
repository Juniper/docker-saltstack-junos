#  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER
#
# Copyright 2016 Juniper Networks, Inc. 
# All rights reserved.
#
# Licensed under the Juniper Networks Script Software License (the "License").
# You may not use this script file except in compliance with the License, which is located at
# http://www.juniper.net/support/legal/scriptlicense/
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Please make sure to run this file as a root user

from ubuntu:14.04
MAINTAINER Iddo Cohen <icohen@juniper.net>

ARG DEBIAN_FRONTEND=noninteractive

# Editing sources and update apt.
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe multiverse restricted" > /etc/apt/sources.list && \
  echo "deb http://archive.ubuntu.com/ubuntu trusty-security main universe multiverse restricted" >> /etc/apt/sources.list && \
  apt-get update && \
  apt-get upgrade -y -o DPkg::Options::=--force-confold

# Packages for PyEZ and SaltStack installation
RUN apt-get install -y --force-yes \
  git git-core curl python-dev \
  libssl-dev libxslt1-dev libxml2-dev libxslt-dev \
  libffi6=3.1~rc1+r3.0.13-12 libffi-dev \
  openssh-server locate vim

# Install PIP via source. Fixed by @ntwrkguru
RUN curl https://bootstrap.pypa.io/get-pip.py | python

### Packages for 64bit systems
###
# For 64bit systems one gets "usr/bin/ld: cannot find -lz" at PyEZ installation, solution install lib32z1-dev and zlib1g-dev
# Note: Because sh -c is executed via Docker, it is not use == but =
###
RUN if [ "$(uname -m)" = "x86_64" ]; then apt-get install -y lib32z1-dev zlib1g-dev; fi

# Installing PyEZ (and its hidden dependencies) and jxmlease for SaltStack salt-proxy
RUN pip install regex junos-eznc jxmlease

### Retrieving bootstrap.sh form SaltStack
###
# Installation manager for SaltStack.
###
RUN curl -Ls http://bootstrap.saltstack.org -o /root/install_salt.sh 

### Installing SaltStack (carbon release).
###
# Carbon release is used to avoid grains/facts bugs with __proxy__.
#
#-M Install master, -d ignore install check, -X do not start the deamons and -P allows pip installation of some packages.
#
###
RUN sh /root/install_salt.sh -d -M -X -P git 2016.11 

### Packages needed for junos_syslog.py SaltStack engine
RUN pip install pyparsing twisted

### Replacing salt-minion configuration
#RUN sed -i "s/^#master: salt/master: localhost/;s/^#id:/id: minion/" /etc/salt/minion

#Slim the container a litte.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/install_salt.sh

#RUN pip install fabric

COPY bin/startup.py /etc/salt/bin/
COPY bin/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
