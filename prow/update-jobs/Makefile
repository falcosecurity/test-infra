SHELL := /bin/bash

VERBOSE ?= 0
ifeq ($(VERBOSE), 0)
# Make is verbose in Linux: let's make it silent.
MAKEFLAGS += --silent
endif

PROJECTNAME := update-jobs
OUTPUT_BASE ?= $(shell pwd)
OUTPUT_PATH := $(OUTPUT_BASE)/bin

# Go variables
GOFILES := $(wildcard *.go)

# Redirect error output to a file, so we can show it in development mode.
STDERR := "/tmp/.$(PROJECTNAME)-stderr.txt"

$(OUTPUT_PATH)/$(PROJECTNAME): $(GOFILES)

build: $(OUTPUT_PATH)/$(PROJECTNAME)
	@echo "  >  Building binary... "
	touch $(STDERR)
	rm $(STDERR)
	mkdir -p $(OUTPUT_PATH)
	go build -o "$(OUTPUT_PATH)/$(PROJECTNAME)" $(GOFILES) 2> $(STDERR)
	cat $(STDERR) | sed -e '1s/.*/\nError:\n/'  | sed 's/make\[.*/ /' | sed "/^/s/^/     /" 1>&2
	@echo "Compiled in: $(OUTPUT_PATH)/$(PROJECTNAME)"

.PHONY: test
test:
	@echo "  >  Executing tests..."
	env GOTRACEBACK=all go test ./...

.PHONY: clean
clean:
	@echo "  >  Cleaning build cache"
	rm $(OUTPUT_PATH)/$(PROJECTNAME) 2> /dev/null
	go clean

.PHONY: list
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) \: 2>/dev/null \
		| awk -v RS= -F: '/^# File/,/^# Finished Make data base/ \
		{if ($$1 !~ "^[#.]") {print $$1}}' | sort | \
		egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
