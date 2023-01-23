SHELL := /bin/bash

DRIVERKIT := $(shell command -v driverkit)
ifeq ($(DRIVERKIT),)
DRIVERKIT := "/bin/driverkit"
endif

ALL_ARCHS := x86_64 aarch64

# Recursive wildcard
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

# Equals function
eq = $(and $(findstring $(1),$(2)),$(findstring $(2),$(1)))

CONFIGS := $(call rwildcard,config/*,*.yaml)
VERSIONS := $(patsubst config/%,%,$(sort $(dir $(wildcard config/*/))))
VERSIONS := $(VERSIONS:/=)
TARGET_VERSION ?= *
TARGET_DISTRO ?= *
TARGET_KERNEL_RELEASE ?= *
TARGET_KERNEL_VERSION ?= *
TARGET_KERNEL ?= ${TARGET_KERNEL_RELEASE}_${TARGET_KERNEL_VERSION}
TARGET_ARCH ?= *
# If TARGET_ARCH value is "*" then we consider all the the supported archs in ALL_ARCHS,
# otherwise we just keep the one passed as parameter.
TARGET_ARCHS := $(if $(call eq,$(TARGET_ARCH),*),$(ALL_ARCHS),$(TARGET_ARCH))
TARGET_HEADERS ?=
TARGET_KERNEL_DEFCONFIG ?=
S3_DRIVERS_BUCKET ?= "falco-distribution"
S3_DRIVERS_KEY_PREFIX ?= "driver"
DRIVERKIT_BACKEND ?= docker
DRIVERKIT_EXTRA_ARGS ?=
SKIP_EXISTING ?= true

validate: $(patsubst config_%,validate/%,$(subst /,_,$(wildcard config/${TARGET_VERSION}*/${TARGET_ARCH}/${TARGET_DISTRO}_${TARGET_KERNEL}.yaml)))

all: $(patsubst config_%,%,$(subst /,_,$(CONFIGS)))

specific_target: $(patsubst config_%,%,$(subst /,_,$(wildcard config/${TARGET_VERSION}*/${TARGET_ARCH}/${TARGET_DISTRO}_${TARGET_KERNEL}.yaml)))

prepare: $(addprefix prepare_,$(VERSIONS))
publish: publish_s3 # alias publish_s3; bintray is no more supported
publish_s3: $(addprefix publish_s3_,$(VERSIONS))

generate:
	$(foreach ARCH,$(TARGET_ARCHS),\
		$(foreach VERSION,$(VERSIONS),\
			utils/generate -a '$(ARCH)' -k '${TARGET_KERNEL}' -r '${TARGET_KERNEL_RELEASE}' -t '${TARGET_KERNEL_VERSION}' -d '${TARGET_DISTRO}' -h '${TARGET_HEADERS}' -v '${VERSION}' -c '${TARGET_KERNEL_DEFCONFIG}'; \
		)\
	)

cleanup:
	$(foreach ARCH,$(TARGET_ARCHS),\
		$(foreach VERSION,$(VERSIONS),\
			rm -rf config/${VERSION}/${ARCH}; \
		)\
	)

# clean old configurations before generating the new ones
generate/auto: cleanup
	$(foreach ARCH,$(TARGET_ARCHS),\
		utils/scrape_and_generate $(ARCH); \
	)

cleanup: cleanup_s3 # alias cleanup_s3; bintray is no more supported
cleanup_s3:
	S3_DRIVERS_BUCKET=${S3_DRIVERS_BUCKET} S3_DRIVERS_KEY_PREFIX=${S3_DRIVERS_KEY_PREFIX} utils/cleanup_s3 $(addprefix -v ,$(VERSIONS))

# $(1): pseudo-target name
# $(2): config file path
define gen_build_targets
validate/$(1): $(2)
	utils/checkfiles $(2)

$(1): validate/$(1) $(2)
	DRIVERKIT=${DRIVERKIT} S3_DRIVERS_BUCKET=${S3_DRIVERS_BUCKET} S3_DRIVERS_KEY_PREFIX=${S3_DRIVERS_KEY_PREFIX} SKIP_EXISTING=${SKIP_EXISTING} DRIVERKIT_BACKEND=${DRIVERKIT_BACKEND} DRIVERKIT_EXTRA_ARGS="${DRIVERKIT_EXTRA_ARGS}" utils/build $(2)
endef

$(foreach CONFIG,$(CONFIGS),\
	$(eval TARGET := $(patsubst config_%,%,$(subst /,_,$(CONFIG))))\
	$(eval $(call gen_build_targets,$(TARGET),$(CONFIG)))\
)

# $(1): driver version
define gen_publish_targets
split_$(1)_kernelmodules:
ifneq ("$(wildcard output/$(1)/x86_64/*.ko)","")
	@mkdir -p output/$(1)/kernel-module/x86_64
	@mv -f output/$(1)/x86_64/*.ko output/$(1)/kernel-module/x86_64
endif
ifneq ("$(wildcard output/$(1)/aarch64/*.ko)","")
	@mkdir -p output/$(1)/kernel-module/aarch64
	@mv -f output/$(1)/aarch64/*.ko output/$(1)/kernel-module/aarch64
endif

split_$(1)_ebpfprobes:
ifneq ("$(wildcard output/$(1)/x86_64/*.o)","")
	@mkdir -p output/$(1)/ebpf-probe/x86_64
	@mv -f output/$(1)/x86_64/*.o output/$(1)/ebpf-probe/x86_64
endif
ifneq ("$(wildcard output/$(1)/aarch64/*.o)","")
	@mkdir -p output/$(1)/ebpf-probe/aarch64
	@mv -f output/$(1)/aarch64/*.o output/$(1)/ebpf-probe/aarch64
endif

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
