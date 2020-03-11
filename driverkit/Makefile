SHELL := /bin/bash

VERSIONS := be1ea2d9482d0e6e2cb14a0fd7e08cbecf517f94
DRIVERKIT ?= $(shell which driverkit)
CONFIGS := $(shell ls config/*)

all: $(addprefix be1ea2d9482d0e6e2cb14a0fd7e08cbecf517f94_, $(notdir $(wildcard config/*)))

# $(1): the driver version
# $(2): the driverkit yaml configuration
define build_driver
$(1)_$(2):
	${DRIVERKIT} docker --loglevel=debug -c $(3) --driverversion $(1)
endef
$(foreach VERSION,$(VERSIONS),\
$(foreach CONFIG,$(CONFIGS),\
	$(eval $(call build_driver,$(VERSION),$(notdir $(CONFIG)),$(CONFIG)))\
)\
)

