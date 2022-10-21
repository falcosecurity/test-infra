#!/usr/bin/env bash
#
# Copyright (C) 2022 The Falco Authors.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

S3_DRIVERS_BUCKET="falco-distribution"
S3_DRIVERS_KEY_PREFIX="driver"

# $1: the program to check
function check_program {
    if hash "$1" 2>/dev/null; then
        type -P "$1" >&/dev/null
    else
        echo "> aborting because $1 is required..." >&2
       return 1
    fi
}

# Meant to be run in the https://github.com/falcosecurity/test-infra repository.
main() {
    # Checks
    check_program "aws"
    check_program "update-drivers-website"
    
    # Build updated json
    update-drivers-website images/update-drivers-website/
    
    # Push the updated files to s3 bucket
    aws s3 cp "images/update-drivers-website/" s3://${S3_DRIVERS_BUCKET}/${S3_DRIVERS_KEY_PREFIX}/site --recursive --include "*.json" --include "index.html" --acl public-read
    
    exit 0
}

main
