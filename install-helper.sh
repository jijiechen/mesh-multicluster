#!/bin/bash

DATA_PLANE_NAME=$1
CONTROL_PLANE_NAME=$2
ISTIO_NAMESPACE=$3

SA=
until [ ! -z "$SA" ] ; do
sleep 1
SA=$(kubectl get serviceaccount/istio-reader-service-account -o Name -n $ISTIO_NAMESPACE --context=ctx-$DATA_PLANE_NAME 2>/dev/null || true)
done

istioctl x create-remote-secret --name $DATA_PLANE_NAME -n $ISTIO_NAMESPACE --context=ctx-$DATA_PLANE_NAME | \
    kubectl apply -n $ISTIO_NAMESPACE --context=ctx-$CONTROL_PLANE_NAME -f -
