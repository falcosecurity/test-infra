SHELL := /bin/bash

DRIVERKIT ?= $(shell which driverkit)

CONFIGS := $(wildcard config/*/*.yaml)
# VERSIONS := $(patsubst config/%,%,$(sort $(dir $(wildcard config/*/))))
# VERSIONS := $(VERSIONS:/=)

all: $(patsubst config_%,%,$(subst /,_,$(CONFIGS)))

# $(1): pseudo-target name
# $(2): driver version
# $(3): config file path
define gen_targets
$(1): $(3)
	@mkdir -p output/$(2)
	@${DRIVERKIT} docker --loglevel=debug -c $(3) --driverversion $(2)
endef
$(foreach CONFIG,$(CONFIGS),\
	$(eval INNER := $(patsubst config/%,%,$(CONFIG)))\
	$(eval VERSION := $(patsubst %/,%,$(dir $(INNER))))\
	$(eval TARGET := $(patsubst config_%,%,$(subst /,_,$(CONFIG))))\
	$(eval $(call gen_targets,$(TARGET),$(VERSION),$(CONFIG)))\
)