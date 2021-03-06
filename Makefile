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
UC = $(UC_E)
PWD = $(TMP)/uc-$(UC_E)
master_name = saltmaster-engine
EXEC = make _exec DEVICE='$(1)' UC='$(UC_E)' CMD='$(2)'
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

DOCKER_EXEC_NONE := docker exec
DOCKER_EXEC += $(DOCKER_EXEC_NONE) -it 
DOCKER_EXEC_MASTER := $(DOCKER_EXEC) $(master_name)
DOCKER_EXEC_MASTER_D := $(DOCKER_EXEC_NONE) $(master_name)

DOCKER_RUN := @docker run -d 
DOCKER_RUN_MASTER := $(DOCKER_RUN) -h $(master_name) 
#DOCKER_RUN_MASTER += --volume $(TMP)/bin:/etc/salt/bin
DOCKER_RUN_MASTER += --volume $(PWD)/docker/salt_proxy.yaml:/etc/salt/proxy
DOCKER_RUN_MASTER += --volume $(PWD)/pillar:/srv/pillar
DOCKER_RUN_MASTER += --volume $(PWD)/reactor:/srv/reactor
DOCKER_RUN_MASTER += --volume $(PWD)/docker/salt_master.yaml:/etc/salt/master

ifeq "$(UC)" "$(UC_B)"
DOCKER_RUN_MASTER += --volume $(PWD)/docker/master:/etc/salt/master.d
DOCKER_RUN_MASTER += --volume $(PWD)/docker/_beacons:/srv/salt/_beacons
endif

ifeq "$(UC)" "$(UC_E)"
DOCKER_RUN_MASTER += --volume $(PWD)/docker/master:/etc/salt/master.d
DOCKER_RUN_MASTER += --volume $(PWD)/engine:/srv/engine
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

# Supid CI... sleep not allowed. Doing python time. Furhtermore, checking if ON_TRAVIS and extending delay...
SLEEP = @if test -z $$ON_TRAVIS; then python -c "import time; time.sleep($(1))"; else python -c "import time; time.sleep($(1)+20)"; fi

.PHONY: build
build:
	docker build --rm -t juniper/saltstack .

.PHONY: master-start
master-start:
	$(DOCKER_RUN_MASTER) --name $(master_name) juniper/saltstack salt-master -l debug

	@touch $(RUN_MINION)
	@touch $(RUN_PROXY)


.PHONY: master-shell
master-shell:
	@$(DOCKER_EXEC_MASTER) bash

#.PHONY: master-keys
#master-keys:
#	@$(DOCKER_EXEC_MASTER) salt-key -L

#.PHONY: accept-keys
#accept-keys:
#	@$(DOCKER_EXEC_MASTER) salt-key -yA

.PHONY: master-sync-beacon
master-sync-beacon:
ifndef DEVICE
	$(error DEVICE parameter is not set.)
else
	@$(DOCKER_EXEC_MASTER) salt '$(DEVICE)' saltutil.sync_beacons
endif

.PHONY: master-clear
master-clean:
	@$(call STOP_RM_DOCKER, $(master_name))

.PHONY: minion-start
minion-start:
ifndef DEVICE
	$(DOCKER_RUN_MINION) juniper/saltstack salt-minion -l debug \
	1>>$(RUN_MINION) && echo -n "Started: " && tail -n1 $(RUN_MINION)
else
	$(DOCKER_RUN_MINION) --name $(DEVICE) -h $(DEVICE) juniper/saltstack salt-minion -l debug \
	1>/dev/null && if [ $$? -eq 0 ]; then echo "$(DEVICE)" >> $(RUN_MINION); echo "Started: $(DEVICE)"; fi
endif	

.PHONY: minion-shell
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

.PHONY: minion-clean
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

#.PHONY: proxy-start
#proxy-start:
#ifndef DEVICE
#	$(error DEVICE parameter is not set. Please use 'make proxy-start DEVICE=<name>')
#else 
#	$(DOCKER_RUN_PROXY) --name $(DEVICE) -h $(DEVICE) juniper/saltstack salt-proxy --proxyid=$(DEVICE) -l debug \
#	1>/dev/null && if [ $$? -eq 0 ]; then echo "$(DEVICE)" >> $(RUN_PROXY); echo "Started: $(DEVICE)"; fi  
#endif

#.PHONY: proxy-shell
#proxy-shell: minion-shell

#.PHONY: proxy-clean
#proxy-clean:
#ifndef DEVICE
#	@while read -r proxy; do \
#		$(call STOP_RM_DOCKER, $$proxy); \
#	done <$(RUN_PROXY)
#	@rm $(RUN_PROXY)
#	@touch $(RUN_PROXY)
#else
#	@$(call STOP_RM_DOCKER, $(DEVICE))
#	@sed -i '/$(DEVICE)/d' $(RUN_PROXY)
#endif


_test:
ifeq "$(UC)" "engine"
	make start-uc-engine
	$(call SLEEP,1)
	$(call VALIDATE,saltmaster-engine)
	$(call SLEEP,5)
	$(call EXEC,$(master_name),bash -c "ps -ef | grep proxy01 | grep -v grep")
	$(call EXEC,$(master_name),salt \proxy01 status.ping_master $(master_name))
	$(call EXEC,$(master_name),salt \proxy01 status.all_status)
	$(call EXEC,$(master_name),bash -c "ps -ef | grep proxy02 | grep -v grep")
	$(call EXEC,$(master_name),salt \proxy02 status.ping_master $(master_name))
	$(call EXEC,$(master_name),salt \proxy02 status.all_status)

	@#$(call EXEC,$(master_name),sed -i "s/^#master: salt/master: $(master_name)/" /etc/salt/minion)
	@#$(call EXEC,$(master_name),salt-call event.send "jnpr/event/proxy01/UI_COMMIT_COMPLETED" "{"host": "172.17.254.1"}")
	@#TODO: Catch the event at master
else
ifeq "$(UC)" "beacon"
	make start-uc-beacon
	$(call SLEEP,1)
	$(call VALIDATE,saltmaster-beacon)
	$(call VALIDATE,minion01)
	
	$(call EXEC,$(master_name),salt \minion01 status.ping_master $(master_name))
	$(call EXEC,$(master_name),salt \minion01 status.all_status)
	$(call EXEC,minion01,bash -c "echo \"Testing ERROR\" >> /var/log/random.log")
	$(call SLEEP,2)
	$(call EXEC,minion01,cat /tmp/random_process_restart.log)
	@echo "Started daemon" > $(PWD)/docker/random.log
endif
endif

.PHONY: test
test:
	make build
	@#make _test
	@#make clean
	make _test UC='beacon'
	make clean UC='beacon'
	make _test UC='engine'
	make clean UC='engine'

.PHONY: start-uc-beacon
start-uc-beacon:
	make master-start UC='beacon'
	make minion-start DEVICE='minion01' UC='beacon'
	$(call SLEEP,10)
	@#make accept-keys UC='beacon'
	@#$(call SLEEP,10)
	make _exec DEVICE='saltmaster-beacon' UC='beacon' CMD='salt "minion01" saltutil.sync_beacons'
	docker restart minion01  

.PHONY: start-uc-engine
start-uc-engine:
	make master-start UC='engine'
	@#make proxy-start DEVICE='proxy01' UC='engine'
	@#$(call SLEEP,30)
	@#make accept-keys UC='engine'
	

clean: master-clean minion-clean
