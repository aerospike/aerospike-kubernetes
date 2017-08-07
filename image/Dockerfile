# ------------------------------------------------------------------------------
# Copyright 2012-2017 Aerospike, Inc.
#
# Portions may be licensed to Aerospike, Inc. under one or more contributor
# license agreements.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
# ------------------------------------------------------------------------------

# ubuntu:xenial is same base as Aerospike 3.10.0.1, saving disk space
FROM ubuntu:xenial

# The peer-finder script provided by google
ADD https://storage.googleapis.com/kubernetes-release/pets/peer-finder /peer-finder

# Local files
ADD install.sh /
ADD on-start.sh /
ADD aerospike.conf /

# Make scripts runnable
RUN chmod -c 755 /peer-finder && chmod -c 755 /install.sh && chmod -c 755 /on-start.sh

ENTRYPOINT /install.sh
