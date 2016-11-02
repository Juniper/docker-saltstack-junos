from ubuntu:14.04

# Editing sources and update apt.
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe multiverse restricted" > /etc/apt/sources.list && \
  echo "deb http://archive.ubuntu.com/ubuntu trusty-security main universe multiverse restricted" >> /etc/apt/sources.list && \
  apt-get update && \
  apt-get upgrade -y -o DPkg::Options::=--force-confold


#
# Using -confold option for, to make sure we are not getting a prompt about configuration files.
#

# Packages for SaltStack installation
RUN apt-get install -y -o DPkg::Options::=--force-confold \
  git \
  git-core \
  wget \
  python-dev \
  python-pip 

# (Optional) Packages for myself
RUN apt-get install -y -o DPkg::Options::=--force-confold \
   openssh-server \
   locate \
   vim

# Packages for PyEZ installation #1
RUN apt-get install -y -o DPkg::Options::=--force-confold \
   libssl-dev \
   libxslt1-dev \
   libxml2-dev \
   libxslt-dev


### Packages for PyEZ installation #2 
###
# Installing older version of libffi6 so libffi-dev can be installed
###
RUN apt-get install -y --force-yes \ 
   libffi6=3.1~rc1+r3.0.13-12 \ 
   libffi-dev

### Packages for 64bit systems
###
# For 64bit systems one gets "usr/bin/ld: cannot find -lz" at PyEZ installation, solution install lib32z1-dev and zlib1g-dev
#
# TODO: Check if it is 64bit system and only then install packages. Does not effect 32bit system but is nicer. 
###
RUN apt-get install -y -o DPkg::Options::=--force-confold \ 
   lib32z1-dev \ 
   zlib1g-dev

# Installing PyEZ
RUN pip install junos-eznc

### Installing of jxmlease
###
# Needed for SaltStack so salt-proxy works with junos module
###
RUN pip install jxmlease

### Retrieving bootstrap.sh form SaltStack
###
# Installation manager for SaltStack.
###
RUN wget -O /root/install_salt.sh http://bootstrap.saltstack.org

### Installing SaltStack (carbon release).
###
# Carbon release to avoid grains/facts bugs with __proxy__.
# 
#-M Install master, -d ignore install check, -X do not start the deamons and -P allows pip installation of some packages. 
#  
###
RUN sh /root/install_salt.sh -d -M -X -P git carbon

#Slim the container a litte.
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

