#!/usr/bin/env bash

set -e

cd images/
for name in golang update-jobs; do make -C $name build-push  ; done