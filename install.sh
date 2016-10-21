#! /bin/bash

# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This volume is assumed to exist and is shared with parent of the init
# container. It contains the mysq config.


# Changes:
# - config volume
# - stripped out work-dir
# - included peer-finder
# - included namespace

CONFIG_VOLUME="/etc/aerospike"
NAMESPACE=${POD_NAMESPACE:-default}
for i in "$@"
do
case $i in
    -c=*|--config=*)
    CONFIG_VOLUME="${i#*=}"
    shift
    ;;
    *)
    # unknown option
    ;;
esac
done

echo installing aerospike.conf into "${CONFIG_VOLUME}"
mkdir -p "${CONFIG_VOLUME}"
chown -R aerospike:aerospike "${CONFIG_VOLUME}"
cp /aerospike.conf "${CONFIG_VOLUME}"/
/peer-finder -on-start=/on-start.sh -service=aerospike -ns=${NAMESPACE}
