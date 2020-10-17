#!/bin/bash

# correctly rename the config files
# $ ./normalize-kubeconfig.sh control.config
# $ export KUBECONFIG=cfg1:cfg2:cfg3
# $ kubectl config view --flatten > merged.config

FILENAME=$1
CLUSTER_NAME=${FILENAME%%.config}


sed -i "s/user: admin/user: admin-$CLUSTER_NAME/" $FILENAME
sed -i "s/name: admin/name: admin-$CLUSTER_NAME/" $FILENAME

sed -i "s/cluster: local/cluster: cluster-$CLUSTER_NAME/" $FILENAME
sed -i "s/name: local/name: cluster-$CLUSTER_NAME/" $FILENAME

CONTEXT_NAME=$(cat ./$FILENAME | grep current-context | cut -d ':' -f 2)
sed -i "s/current-context:$CONTEXT_NAME/current-context: ctx-$CLUSTER_NAME/" $FILENAME
sed -i "s/name:$CONTEXT_NAME/name: ctx-$CLUSTER_NAME/" $FILENAME


