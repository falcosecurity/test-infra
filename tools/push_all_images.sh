#!/usr/bin/env bash

set -e

cd images/
for name in golang update-jobs build-drivers docker-dind; do make -C $name build-push  ; done