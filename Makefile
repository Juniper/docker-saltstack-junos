master_name = saltmaster
PWD = $(shell pwd)

DOCKER_EXEC := docker exec -i -t  
DOCKER_EXEC_MASTER := $(DOCKER_EXEC) $(master_name)

DOCKER_RUN := docker run -d 
DOCKER_LINK := $(DOCKER_RUN) --link $(master_name):$(master_name)

DOCKER_RUN_MINION := $(DOCKER_LINK) --volume $(PWD)/docker/salt_minion.yaml:/etc/salt/minion
DOCKER_RUN_PROXY := $(DOCKER_LINK) --volume $(PWD)/docker/salt_proxy.yaml:/etc/salt/proxy


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
	
	touch $(PWD)/started_minions
	touch $(PWD)/started_proxies

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
	$(DOCKER_RUN_MINION) juniper/saltstack salt-minion 2>/dev/null 1>>$(PWD)/started_minions
else
	$(DOCKER_RUN_MINION) --name $(DEVICE) juniper/saltstack salt-minion \
	2>/dev/null && if [ $$? -eq 0 ]; then echo $(DEVICE) >> $(PWD)/started_minions; fi
endif	


minion-clean:
ifndef DEVICE
	@while read -r minion; do \
 		docker stop $$minion && docker rm $$minion; \
	done <$(PWD)/started_minions
else
	docker stop $(DEVICE) && docker rm $(DEVICE) && \
	sed -i '/$(DEVICE)/d' $(PWD)/started_minions
endif

proxy-start:
ifndef DEVICE
	$(error DEVICE parameter is not set. Please use 'make proxy-start DEVICE=<name>')
else 
	$(DOCKER_RUN_PROXY) --name $(DEVICE) juniper/saltstack salt-proxy --proxyid=$(DEVICE) \
	2>/dev/null && if [ $$? -eq 0 ]; then echo $(DEVICE) >> $(PWD)/started_proxies; fi  
endif

proxy-clean:
ifndef DEVICE
	@while read -r proxy; do \
		docker stop $$proxy && docker rm $$proxy; \
	done <$(PWD)/started_proxies
else
	docker stop $(DEVICE) && docker rm $(DEVICE) && \
	sed -i '/$(DEVICE)/d' $(PWD)/started_proxies
endif

clean-not-master: minion-clean proxy-clean
 
clean: master-clean minion-clean proxy-clean
