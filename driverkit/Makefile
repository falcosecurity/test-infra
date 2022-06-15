SHELL := /bin/bash

DRIVERKIT := $(shell command -v driverkit)
ifeq ($(DRIVERKIT),)
DRIVERKIT := "/bin/driverkit"
endif

# Recursive wildcard
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

CONFIGS := $(call rwildcard,config/*,*.yaml)
VERSIONS := $(patsubst config/%,%,$(sort $(dir $(wildcard config/*/))))
VERSIONS := $(VERSIONS:/=)
TARGET_VERSION ?= *
TARGET_DISTRO ?= *
TARGET_KERNEL ?= *
TARGET_ARCH ?= *
TARGET_HEADERS ?=
S3_DRIVERS_BUCKET ?= "falco-distribution"
S3_DRIVERS_KEY_PREFIX ?= "driver"
SKIP_EXISTING ?= true

validate: validate_old validate_new
# old fmt had x86_64 only in root folder. Note: this breaks filtering for TARGET_ARCH
# because validate_old will always validate any old config.
# Not a big deal because we were not going to filter for TARGET_ARCH in any case.
validate_old: $(patsubst config_%,validate/%,$(subst /,_,$(wildcard config/${TARGET_VERSION}*/${TARGET_DISTRO}_${TARGET_KERNEL}-*)))
# new fmt has $arch subfolders
validate_new: $(patsubst config_%,validate/%,$(subst /,_,$(wildcard config/${TARGET_VERSION}*/${TARGET_ARCH}/${TARGET_DISTRO}_${TARGET_KERNEL}-*)))

all: $(patsubst config_%,%,$(subst /,_,$(CONFIGS)))

specific_target: specific_target_old specific_target_new
# old fmt had x86_64 only in root folder. Note: this breaks filtering for TARGET_ARCH
# because specific_target_old will always build any old config.
# Not a big deal because we were not going to filter for TARGET_ARCH in any case.
specific_target_old: $(patsubst config_%,%,$(subst /,_,$(wildcard config/${TARGET_VERSION}*/${TARGET_DISTRO}_${TARGET_KERNEL}-*)))
# new fmt has $arch subfolders
specific_target_new: $(patsubst config_%,%,$(subst /,_,$(wildcard config/${TARGET_VERSION}*/${TARGET_ARCH}/${TARGET_DISTRO}_${TARGET_KERNEL}-*)))

prepare: $(addprefix prepare_,$(VERSIONS))
publish: $(addprefix publish_,$(VERSIONS))
publish_s3: $(addprefix publish_s3_,$(VERSIONS))

generate:
	$(foreach VERSION,$(VERSIONS),\
		utils/generate -a $(TARGET_ARCH) -k ${TARGET_KERNEL} -d ${TARGET_DISTRO} -h ${TARGET_HEADERS} -v ${VERSION}; \
	)

generate/auto:
	utils/scrape_and_generate "x86_64"
	utils/scrape_and_generate "aarch64"

cleanup:
	utils/cleanup -p ${BINTRAY_SECRET} $(addprefix -v ,$(VERSIONS))

cleanup_s3:
	S3_DRIVERS_BUCKET=${S3_DRIVERS_BUCKET} S3_DRIVERS_KEY_PREFIX=${S3_DRIVERS_KEY_PREFIX} utils/cleanup_s3 $(addprefix -v ,$(VERSIONS))

# $(1): pseudo-target name
# $(2): config file path
define gen_build_targets
validate/$(1): $(2)
	utils/checkfiles $(2)

$(1): validate/$(1) $(2)
	DRIVERKIT=${DRIVERKIT} S3_DRIVERS_BUCKET=${S3_DRIVERS_BUCKET} S3_DRIVERS_KEY_PREFIX=${S3_DRIVERS_KEY_PREFIX} SKIP_EXISTING=${SKIP_EXISTING} utils/build $(2)
endef

$(foreach CONFIG,$(CONFIGS),\
	$(eval TARGET := $(patsubst config_%,%,$(subst /,_,$(CONFIG))))\
	$(eval $(call gen_build_targets,$(TARGET),$(CONFIG)))\
)

# $(1): driver version
define gen_publish_targets
split_$(1)_kernelmodules:
# root is old x86_64
ifneq ("$(wildcard output/$(1)/*.ko)","")
	@mkdir -p output/$(1)/kernel-module
	@mv -f output/$(1)/*.ko output/$(1)/kernel-module
endif
ifneq ("$(wildcard output/$(1)/x86_64/*.ko)","")
	@mkdir -p output/$(1)/kernel-module/x86_64
	@mv -f output/$(1)/x86_64/*.ko output/$(1)/kernel-module/x86_64
endif
ifneq ("$(wildcard output/$(1)/aarch64/*.ko)","")
	@mkdir -p output/$(1)/kernel-module/aarch64
	@mv -f output/$(1)/aarch64/*.ko output/$(1)/kernel-module/aarch64
endif

split_$(1)_ebpfprobes:
# root is old x86_64
ifneq ("$(wildcard output/$(1)/*.o)","")
	@mkdir -p output/$(1)/ebpf-probe
	@mv -f output/$(1)/*.o output/$(1)/ebpf-probe
endif
ifneq ("$(wildcard output/$(1)/x86_64/*.o)","")
	@mkdir -p output/$(1)/ebpf-probe/x86_64
	@mv -f output/$(1)/x86_64/*.o output/$(1)/ebpf-probe/x86_64
endif
ifneq ("$(wildcard output/$(1)/aarch64/*.o)","")
	@mkdir -p output/$(1)/ebpf-probe/aarch64
	@mv -f output/$(1)/aarch64/*.o output/$(1)/ebpf-probe/aarch64
endif

prepare_$(1): split_$(1)_kernelmodules split_$(1)_ebpfprobes
	@echo "upserting falcosecurity/driver/kernel-module/$(1) version..."
	jfrog bt vs falcosecurity/driver/kernel-module/$(1) --user poiana --key ${BINTRAY_SECRET} || jfrog bt vc falcosecurity/driver/kernel-module/$(1) --desc="Falco kernel module" --released=`date -u +"%Y-%m-%dT%H:%M:%S.000Z"` --user poiana --key ${BINTRAY_SECRET}
	@echo "upserting falcosecurity/driver/ebpf-probe/$(1) version..."
	jfrog bt vs falcosecurity/driver/ebpf-probe/$(1) --user poiana --key ${BINTRAY_SECRET} || jfrog bt vc falcosecurity/driver/ebpf-probe/$(1) --desc="Falco eBPF probe" --released=`date -u +"%Y-%m-%dT%H:%M:%S.000Z"` --user poiana --key ${BINTRAY_SECRET}

publish_$(1): prepare_$(1)
	@echo "publishing kernel modules (version $(1)) to bintray ..."
	jfrog bt u "output/$(1)/kernel-module/*" falcosecurity/driver/kernel-module/$(1) $(1)/ --user poiana --key ${BINTRAY_SECRET} --publish --override
	@echo "publishing eBPF probes (version $(1)) to bintray ..."
	jfrog bt u "output/$(1)/ebpf-probe/*" falcosecurity/driver/ebpf-probe/$(1) $(1)/ --user poiana --key ${BINTRAY_SECRET} --publish --override

publish_s3_$(1): split_$(1)_kernelmodules split_$(1)_ebpfprobes
	if [ -d "output/$(1)/ebpf-probe" ]; then \
			echo "publishing eBPF probes (version $(1)) to S3 ..."; \
			aws s3 cp "output/$(1)/ebpf-probe/" s3://${S3_DRIVERS_BUCKET}/${S3_DRIVERS_KEY_PREFIX}/$(1) --recursive --exclude "*" --include "*.o" --acl public-read; \
	fi
	if [ -d "output/$(1)/kernel-module" ]; then \
			echo "publishing kernel modules (version $(1)) to S3 ..."; \
			aws s3 cp "output/$(1)/kernel-module/" s3://${S3_DRIVERS_BUCKET}/${S3_DRIVERS_KEY_PREFIX}/$(1) --recursive --exclude "*" --include "*.ko" --acl public-read; \
	fi

endef
$(foreach VERSION,$(VERSIONS),\
	$(eval $(call gen_publish_targets,$(VERSION)))\
)

.PHONY: clean
clean:
	find output/ -not -name '.gitignore' -not -name 'output' -delete

stats:
	@utils/driverstats
