# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER
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

master_name = saltmaster
PWD = $(shell pwd)

DOCKER_EXEC := docker exec -i -t  
DOCKER_EXEC_MASTER := $(DOCKER_EXEC) $(master_name)

DOCKER_RUN := docker run -d 
DOCKER_LINK := $(DOCKER_RUN) --link $(master_name):$(master_name)

DOCKER_RUN_MINION := $(DOCKER_LINK) --volume $(PWD)/docker/salt_minion.yaml:/etc/salt/minion
DOCKER_RUN_PROXY := $(DOCKER_LINK) --volume $(PWD)/docker/salt_proxy.yaml:/etc/salt/proxy

RUN_PATH := $(PWD)/run
RUN_MINION += $(RUN_PATH)/started_minions.log
RUN_PROXY +=  $(RUN_PATH)/started_proxies.log

build:
	docker build -t juniper/saltstack .

master-start:
	docker run -d \
	  	--volume $(PWD)/pillar:/srv/pillar \
		--volume $(PWD)/reactor:/srv/reactor \
		--volume $(PWD)/engine:/srv/engine \
		--volume $(PWD)/docker/salt_master.yaml:/etc/salt/master \
		--publish 8516:516/udp \
		--name $(master_name) juniper/saltstack salt-master
	
	touch $(RUN_MINION)
	touch $(RUN_PROXY)

master-shell:
	$(DOCKER_EXEC_MASTER) bash

master-keys:
	$(DOCKER_EXEC_MASTER) salt-key -L

accept-keys:
	$(DOCKER_EXEC_MASTER) salt-key -yA

master-clean:
	docker stop $(master_name)
	docker rm $(master_name)

minion-start:
ifndef DEVICE
	$(DOCKER_RUN_MINION) juniper/saltstack salt-minion 2>/dev/null 1>>$(RUN_MINION)
else
	$(DOCKER_RUN_MINION) --name $(DEVICE) juniper/saltstack salt-minion -l warning \
	2>/dev/null && if [ $$? -eq 0 ]; then echo "$(DEVICE)" >> $(RUN_MINION); fi
endif	


minion-clean:
ifndef DEVICE
	@while read -r minion; do \
 		docker stop $$minion && \
		docker rm $$minion; \
	done <$(RUN_MINION)
else
	docker stop $(DEVICE) && \
	docker rm $(DEVICE) && \
	sed -i '/$(DEVICE)/d' $(RUN_MINION)
endif

proxy-start:
ifndef DEVICE
	$(error DEVICE parameter is not set. Please use 'make proxy-start DEVICE=<name>')
else 
	$(DOCKER_RUN_PROXY) --name $(DEVICE) juniper/saltstack salt-proxy --proxyid=$(DEVICE) -l warning \
	2>/dev/null && if [ $$? -eq 0 ]; then echo $(DEVICE) >> $(RUN_PROXY); fi  
endif

proxy-clean:
ifndef DEVICE
	@while read -r proxy; do \
		docker stop $$proxy && \
		docker rm $$proxy; \
	done <$(RUN_PROXY)
else
	docker stop $(DEVICE) && \
	docker rm $(DEVICE) && \
	sed -i '/$(DEVICE)/d' $(RUN_PROXY)
endif

clean-not-master: minion-clean proxy-clean
 
clean: master-clean minion-clean proxy-clean
