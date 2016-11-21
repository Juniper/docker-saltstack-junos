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

TMP = $(shell pwd)

UC_E = engine
UC_B = beacon

ifndef UC
PWD = $(TMP)/uc-default
master_name = saltmaster-default
EXEC = make _exec DEVICE='$(1)' CMD='$(2)'
else
ifeq "$(UC)" "$(UC_E)"
PWD = $(TMP)/uc-$(UC_E)
master_name = saltmaster-engine
EXEC = make _exec DEVICE='$(1)' UC='$(UC_E)' CMD='$(2)'
else
ifeq "$(UC)" "$(UC_B)"
PWD = $(TMP)/uc-$(UC_B)
master_name = saltmaster-beacon
EXEC = make _exec DEVICE='$(1)' UC='$(UC_B)' CMD='$(2)'
else
$(error Use case "$(UC)" does not exist)
endif
endif
endif

RUN_PATH := $(PWD)/run
RUN_MINION += $(RUN_PATH)/started_minions.log
RUN_PROXY +=  $(RUN_PATH)/started_proxies.log

DOCKER_EXEC := docker exec -i -t  
DOCKER_EXEC_MASTER := $(DOCKER_EXEC) $(master_name)

DOCKER_RUN := @docker run -d 
DOCKER_RUN_MASTER := $(DOCKER_RUN) -h $(master_name) 
DOCKER_RUN_MASTER += --volume $(PWD)/pillar:/srv/pillar

ifdef UC
DOCKER_RUN_MASTER += --volume $(PWD)/reactor:/srv/reactor
endif

ifeq "$(UC)" "$(UC_B)"
DOCKER_RUN_MASTER += --volume $(PWD)/docker/master:/etc/salt/master.d
DOCKER_RUN_MASTER += --volume $(PWD)/docker/_beacons:/srv/salt/_beacons
endif

ifeq "$(UC)" "$(UC_E)"
DOCKER_RUN_MASTER += --volume $(PWD)/docker/salt_master.yaml:/etc/salt/master
DOCKER_RUN_MASTER += --volume $(PWD)/docker/master:/etc/salt/master.d
DOCKER_RUN_MASTER += --volume $(PWD)/engine:/srv/engine
endif

ifeq "$(UC)" "$(UC_E)"
DOCKER_RUN_MASTER += --publish 8516:516/udp
endif

DOCKER_LINK := $(DOCKER_RUN) --link $(master_name):$(master_name)

DOCKER_RUN_MINION := $(DOCKER_LINK) 
DOCKER_RUN_MINION += --volume $(PWD)/docker/salt_minion.yaml:/etc/salt/minion
ifeq "$(UC)" "$(UC_B)"
DOCKER_RUN_MINION += --volume $(PWD)/docker/random.log:/var/log/random.log
endif

DOCKER_RUN_PROXY := $(DOCKER_LINK) 
DOCKER_RUN_PROXY += --volume $(PWD)/docker/salt_proxy.yaml:/etc/salt/proxy

STOP_RM_DOCKER = echo "Stopping:$(1)" && docker stop $(1) 1>/dev/null && echo "Removing:" $(1) && docker rm $(1) 1>/dev/null

#TODO: Accept a key automatically at master for minion/proxy when spinning up.
#ACCEPT_SPECIFIC_KEY = $(DOCKER_EXEC_MASTER) salt-key -ya $(1)


VALIDATE = @if ! docker ps | grep "$(1)" > /dev/null ; then echo "Failed: Test of starting $(1) $(UC)"; exit 1; fi 
VALIDATE_NOT = @if docker ps -a | grep "$(1)" > /dev/null ; then echo "Failed: Test of cleaning $(1) $(UC)"; exit 1; fi 

build:
	docker build --rm -t juniper/saltstack .

master-start:
	$(DOCKER_RUN_MASTER) --name $(master_name) juniper/saltstack salt-master -l debug 
	
	@touch $(RUN_MINION)
	@touch $(RUN_PROXY)

master-shell:
	@$(DOCKER_EXEC_MASTER) bash

master-keys:
	@$(DOCKER_EXEC_MASTER) salt-key -L

accept-keys:
	@$(DOCKER_EXEC_MASTER) salt-key -yA

master-sync-beacon:
ifndef DEVICE
	$(error DEVICE parameter is not set.)
else
	@$(DOCKER_EXEC_MASTER) salt '$(DEVICE)' saltutil.sync_beacons
endif

master-clean:
	@$(call STOP_RM_DOCKER, $(master_name))


minion-start:
ifndef DEVICE
	$(DOCKER_RUN_MINION) juniper/saltstack salt-minion -l debug \
	1>>$(RUN_MINION) && echo -n "Started: " && tail -n1 $(RUN_MINION)
else
	$(DOCKER_RUN_MINION) --name $(DEVICE) -h $(DEVICE) juniper/saltstack salt-minion -l debug \
	1>/dev/null && if [ $$? -eq 0 ]; then echo "$(DEVICE)" >> $(RUN_MINION); echo "Started: $(DEVICE)"; fi
endif	

minion-shell:
ifndef DEVICE
	$(error DEVICE parameter is not set.)
else
	@$(DOCKER_EXEC) $(DEVICE) bash
endif

_exec:
ifndef DEVICE
	$(error DEVICE parameter is not set.)
else
ifndef CMD
	$(error CMD parameter is not set.)
else
	$(DOCKER_EXEC) $(DEVICE) $(CMD)
endif
endif



minion-clean:
ifndef DEVICE
	@while read -r minion; do \
		$(call STOP_RM_DOCKER, $$minion); \
	done <$(RUN_MINION)
	@rm $(RUN_MINION)
	@touch $(RUN_MINION)
else
	@$(call STOP_RM_DOCKER, $(DEVICE))
	@sed -i '/$(DEVICE)/d' $(RUN_MINION)
endif

proxy-start:
ifndef DEVICE
	$(error DEVICE parameter is not set. Please use 'make proxy-start DEVICE=<name>')
else 
	$(DOCKER_RUN_PROXY) --name $(DEVICE) -h $(DEVICE) juniper/saltstack salt-proxy --proxyid=$(DEVICE) -l debug \
	1>/dev/null && if [ $$? -eq 0 ]; then echo "$(DEVICE)" >> $(RUN_PROXY); echo "Started: $(DEVICE)"; fi  
endif

proxy-shell: minion-shell

proxy-clean:
ifndef DEVICE
	@while read -r proxy; do \
		$(call STOP_RM_DOCKER, $$proxy); \
	done <$(RUN_PROXY)
	@rm $(RUN_PROXY)
	@touch $(RUN_PROXY)
else
	@$(call STOP_RM_DOCKER, $(DEVICE))
	@sed -i '/$(DEVICE)/d' $(RUN_PROXY)
endif


_test:
ifndef UC
	make master-start
	$(call VALIDATE,saltmaster-default)

	make minion-start DEVICE='minion01'
	$(call VALIDATE,minion01)
	
	make proxy-start DEVICE='vmx'	
	$(call VALIDATE,vmx)
	
	make minion-start DEVICE='clean-minion01'
	@sleep 5;
	
	make accept-keys
	@sleep 10;
	
	make minion-clean DEVICE='clean-minion01'
	$(call VALIDATE_NOT,clean-minion01)
	
	$(call EXEC,$(master_name),salt \minion01 status.ping_master $(master_name))
	$(call EXEC,$(master_name),salt \vmx status.ping_master $(master_name))
	$(call EXEC,$(master_name),salt \minion01 status.all_status)
	$(call EXEC,$(master_name),salt \vmx status.all_status)
else
ifeq "$(UC)" "engine"
	make start-uc-engine
	@sleep 10;
	
	$(call VALIDATE,saltmaster-engine)
	$(call VALIDATE,proxy01)
	
	$(call EXEC,$(master_name),salt \proxy01 status.ping_master $(master_name))
	$(call EXEC,$(master_name),salt \proxy01 status.all_status)
	$(call EXEC,proxy01,sed -i "s/^#master: salt/master: $(master_name)/" /etc/salt/minion)
	$(call EXEC,proxy01,salt-call event.send "jnpr/event/proxy01/UI_COMMIT_COMPLETED" "{"host": "172.17.254.1"}")
	#TODO: Catch the event at master
else
ifeq "$(UC)" "beacon"
	make start-uc-beacon
	@sleep 10;
	
	$(call VALIDATE,saltmaster-beacon)
	$(call VALIDATE,minion01)
	
	$(call EXEC,$(master_name),salt \minion01 status.ping_master $(master_name))
	$(call EXEC,$(master_name),salt \minion01 status.all_status)
	$(call EXEC,minion01,bash -c "echo \"Testing ERROR\" >> /var/log/random.log")
	@sleep 2;
	$(call EXEC,minion01,cat /tmp/random_process_restart.log)
	echo "Started daemon" > $(PWD)/docker/random.log
endif
endif
endif

test:
	make build
	#make _test
	#make clean
	make _test UC='beacon'
	make clean UC='beacon'
	#make _test UC='engine'
	##make clean UC='engine'

start-uc-beacon:
	make master-start UC='beacon'
	make minion-start DEVICE='minion01' UC='beacon'
	@sleep 5;
	make accept-keys UC='beacon'
	@sleep 10;
	make _exec DEVICE='saltmaster-beacon' UC='beacon' CMD='salt "minion01" saltutil.sync_beacons'
	docker restart minion01

start-uc-engine:
	make master-start UC='engine'
	make proxy-start DEVICE='proxy01' UC='engine'
	@sleep 5;
	make accept-keys UC='engine'
	

clean: master-clean minion-clean proxy-clean
