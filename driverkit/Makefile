SHELL := /bin/bash

VERSIONS := be1ea2d9482d0e6e2cb14a0fd7e08cbecf517f94 dev
DRIVERKIT ?= $(shell which driverkit)
CONFIGS := $(wildcard config/*.yaml)

define all
all: $(1)
endef
$(foreach VERSION,$(VERSIONS),\
	$(eval $(call all,$(addprefix $(VERSION)_,$(notdir $(CONFIGS)))))\
)

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

