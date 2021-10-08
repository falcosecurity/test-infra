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

PUBLISH_S3="${PUBLISH_S3:=false}"
PUBLISH_TAG="${PUBLISH_TAG:=dev}"

s3_dest_path=$S3_PATH/$PUBLISH_TAG/

# Build
./build.sh

# Publish
if "$PUBLISH_S3"; then
    dest_path=$(mktemp -d)
    
    for source_folder in plugins/*/ ; do
        name=$(echo $source_folder | cut -f2 -d'/')
        dest_folder=$dest_path/$name
        mkdir -p $dest_folder
        cp $source_folder/*.so $dest_folder/
        cp $source_folder/README.md $dest_folder/
    done
    
    echo "> Cleaning up destination path on S3 ($s3_dest_path)"
    aws s3 rm --recursive $s3_dest_path
    
    echo "> Uploading plugins to S3"
    aws s3 cp --recursive $dest_path $s3_dest_path
else
    echo "> Publishing skipped due to configuration"
fi
