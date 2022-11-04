#!/usr/bin/env bash
#
# Copyright (C) 2021 The Falco Authors.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

OUTPUT_DIR="${OUTPUT_DIR:=output}"
PUBLISH_S3="${PUBLISH_S3:=false}"
PUBLISH_TAG="${PUBLISH_TAG:=dev}"

# see: https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
# note: we have a capturing group for the plugin name prefix, so that we can use
# it to specify the right make release target
VERSION_RGX="^([a-z]+[a-z0-9_\-]*)-(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?$"

if [[ $PULL_BASE_REF =~ $VERSION_RGX ]];
then
    # Build only tagged package
    # note: BASH_REMATCH[1] points to the first capturing group of the matching
    # regex, which is the plugin name
    make release/${BASH_REMATCH[1]}

    # Publish artifacts in "stable" dir
    PUBLISH_TAG="stable"
else
    # Build all dev packages
    make packages
fi

# Publish
if "$PUBLISH_S3"; then
    echo "> Uploading plugins to S3"
    for package in $OUTPUT_DIR/*.tar.gz; do
        aws s3 cp --no-progress $package ${S3_PATH%/}/$PUBLISH_TAG/
    done
else
    echo "> Publishing skipped due to configuration"
fi
