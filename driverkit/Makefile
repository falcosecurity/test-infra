SHELL := /bin/bash

VERSIONS := be1ea2d9482d0e6e2cb14a0fd7e08cbecf517f94
DRIVERKIT ?= $(shell which driverkit)

# $(1): the driver version
# $(2): the driverkit yaml configuration
define build_driver
$(1):
	${DRIVERKIT} docker --loglevel=debug -c $(2) --driverversion $(1)
endef
$(foreach VERSION,$(VERSIONS),\
	$(eval $(call build_driver,$(VERSION), config/centos_4.18.0-147.5.1.el8_1.x86_64.yaml))\
)
