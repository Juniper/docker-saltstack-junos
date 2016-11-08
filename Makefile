

master_name = saltmaster
PWD = $(shell pwd)

build:
	docker build -t juniper/saltstack .

master-start:
	docker run -d \
	  --volume $(PWD)/pillar:/srv/pillar \
		--name $(master_name) juniper/saltstack salt-master

master-shell:
	docker exec -i -t $(master_name) bash

master-keys:
	docker exec -i -t $(master_name) salt-key -L

proxy-start:
	docker run -d \
		--link $(master_name):$(master_name) \
		--volume $(PWD)/docker/salt_proxy.yaml:/etc/salt/proxy \
		juniper/saltstack salt-proxy --proxyid=$(DEVICE)
