#! /bin/bash
# ------------------------------------------------------------------------------
# Copyright 2012-2019 Aerospike, Inc.
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

# This script writes out an aerospike config using a list of newline seperated
# peer DNS names it accepts through stdin.

# /etc/aerospike is assumed to be a shared volume so we can modify aerospike.conf as required


set -e
set -x
CFG=/etc/aerospike/aerospike.template.conf

# Auto generate Node IDs and add to config
if [ "$AUTO_GENERATE_NODE_IDS" = true ]
then
    if ! grep -q "node-id" ${CFG}
    then
        INDEX=${POD_NAME##*-}
        sed -i "/service[[:blank:]]*{/{p;s/.*/1/;H;g;/^\(\n1\)\{1\}$/s//\tnode-id a$INDEX/p;d}" ${CFG}
    else
        printf "AUTO_GENERATE_NODE_IDS is true but node-id is already configured! \n"
    fi
fi

# For GKE/EKS assign external IP to alternate-access-address
# if hostnetworking is enabled
if [ "$HOST_NETWORK" = true ]
then
	apt-get update -y
	apt-get install curl -y
	if [ "$PLATFORM" = "gke" ]
	then
		ret=$(curl --write-out "%{http_code}\n" --silent --output /dev/null -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
		if [ $ret = 200 ]
        then
            EXT_IP=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
            if [ ! -z $EXT_IP ] && [ "$EXT_IP" != "" ]
			then
				echo "External IP:$EXT_IP"
               	sed -i "/service[[:blank:]]*{/{p;s/.*/1/;H;g;/^\(\n1\)\{2\}$/s//\t\talternate-access-address ${EXT_IP}/p;d}" ${CFG}
			fi
        fi
	elif [ "$PLATFORM" = "eks" ]
	then
		ret=$(curl --write-out "%{http_code}\n" --silent --output /dev/null http://169.254.169.254/latest/meta-data/public-ipv4)
		if [ $ret = 200 ]
		then 
			EXT_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
			if [ ! -z $EXT_IP ] && [ "$EXT_IP" != "" ]
            then
                echo "External IP: $EXT_IP"
                sed -i "/service[[:blank:]]*{/{p;s/.*/1/;H;g;/^\(\n1\)\{2\}$/s//\t\talternate-access-address ${EXT_IP}/p;d}" ${CFG}
            fi
		fi
	fi
fi

function join {
    local IFS="$1"; shift; echo "$*";
}

HOSTNAME=$(hostname)
# Parse out cluster name, formatted as: petset_name-index
IFS='-' read -ra ADDR <<< "$(hostname)"
CLUSTER_NAME="${ADDR[0]}"

while read -ra LINE; do
    if [[ "${LINE}" == *"${HOSTNAME}"* ]]; then
        MY_NAME=$LINE
    fi
    PEERS=("${PEERS[@]}" $LINE)
done

for PEER in "${PEERS[@]}"; do
	sed -i -e "/mesh-seed-placeholder/a \\\t\tmesh-seed-address-port ${PEER} 3002" ${CFG}
done


# don't need a restart, we're just writing the conf in case there's an
# unexpected restart on the node.
