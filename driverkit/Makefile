SHELL := /bin/bash

DRIVERKIT ?= $(shell which driverkit)

CONFIGS := $(wildcard config/*/*.yaml)
VERSIONS := $(patsubst config/%,%,$(sort $(dir $(wildcard config/*/))))
VERSIONS := $(VERSIONS:/=)

all: $(patsubst config_%,%,$(subst /,_,$(CONFIGS)))

publish: $(addprefix publish_,$(VERSIONS))

# $(1): pseudo-target name
# $(2): driver version
# $(3): config file path
define gen_build_targets
$(1): $(3)
	@mkdir -p output/$(2)
	@${DRIVERKIT} docker --loglevel=debug -c $(3) --driverversion $(2)
endef
$(foreach CONFIG,$(CONFIGS),\
	$(eval INNER := $(patsubst config/%,%,$(CONFIG)))\
	$(eval VERSION := $(patsubst %/,%,$(dir $(INNER))))\
	$(eval TARGET := $(patsubst config_%,%,$(subst /,_,$(CONFIG))))\
	$(eval $(call gen_build_targets,$(TARGET),$(VERSION),$(CONFIG)))\
)

# $(1): driver version
define gen_publish_targets
publish_$(1): output/$(1)
	@echo "upserting falcosecurity/module/$(1) version..."
	@echo "publishing to bintray ..."
	@echo "upserting falcosecurity/probe/$(1) version..."
	@echo "publishing to bintray ..."
endef
$(foreach VERSION,$(VERSIONS),\
	$(eval $(call gen_publish_targets,$(VERSION)))\
)