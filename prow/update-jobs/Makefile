SHELL := /bin/bash

VERBOSE ?= 0
ifeq ($(VERBOSE), 0)
# Make is verbose in Linux: let's make it silent.
MAKEFLAGS += --silent
endif

PROJECTNAME := update-jobs
BASE := $(shell pwd)
OUTPUT := $(BASE)/bin

# Go variables
GOFILES := $(wildcard *.go)

# Redirect error output to a file, so we can show it in development mode.
STDERR := "/tmp/.$(PROJECTNAME)-stderr.txt"

$(OUTPUT)/$(PROJECTNAME): $(GOFILES)

build: $(OUTPUT)/$(PROJECTNAME)
	@echo "  >  Building binary..."
	touch $(STDERR)
	rm $(STDERR)
	mkdir -p $(OUTPUT)
	go build -o "$(OUTPUT)/$(PROJECTNAME)" $(GOFILES) 2> $(STDERR)
	cat $(STDERR) | sed -e '1s/.*/\nError:\n/'  | sed 's/make\[.*/ /' | sed "/^/s/^/     /" 1>&2

test:
	@echo "  >  Executing tests..."
	env GOTRACEBACK=all go test ./...

clean:
	@echo "  >  Cleaning build cache"
	rm $(OUTPUT)/$(PROJECTNAME) 2> /dev/null
	go clean
