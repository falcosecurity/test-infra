SHELL := /bin/bash

DRIVERKIT ?= $(shell which driverkit)

CONFIGS := $(wildcard config/*/*.yaml)
VERSIONS := $(patsubst config/%,%,$(sort $(dir $(wildcard config/*/))))
VERSIONS := $(VERSIONS:/=)

all: $(patsubst config_%,%,$(subst /,_,$(CONFIGS)))

prepare: $(addprefix prepare_,$(VERSIONS))
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
split_$(1)_kernelmodules:
ifneq ("$(wildcard output/$(1)/*.ko)","")
	@mkdir -p output/$(1)/kernel-module
	@mv -f output/$(1)/*.ko output/$(1)/kernel-module
endif

split_$(1)_ebpfprobes:
ifneq ("$(wildcard output/$(1)/*.o)","")
	@mkdir -p output/$(1)/ebpf-probe
	@mv -f output/$(1)/*.o output/$(1)/ebpf-probe
endif

prepare_$(1): split_$(1)_kernelmodules split_$(1)_ebpfprobes
	@echo "upserting falcosecurity/driver/kernel-module/$(1) version..."
	@echo "upserting falcosecurity/driver/ebpf-probe/$(1) version..."

publish_$(1): prepare_$(1)
	@echo "publishing kernel modules to bintray ..."
	@echo "publishing eBPF probes to bintray ..."
endef
$(foreach VERSION,$(VERSIONS),\
	$(eval $(call gen_publish_targets,$(VERSION)))\
)

.PHONY: clean
clean:
	@find output -type f -not -name '.gitignore' -delete