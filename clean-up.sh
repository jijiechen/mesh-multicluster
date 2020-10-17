#!/bin/bash


CONTROL_PLANE_NAME=$1
DATA_PLAINE_CTXS=$2

ISTIO_NAMESPACE=istio-system
DATA_PLAINE_NAMES=(${DATA_PLAINE_CTXS//,/ })


istioctl manifest generate -f ./.install/control-plane.yaml -n $ISTIO_NAMESPACE --context=ctx-${CONTROL_PLANE_NAME} | kubectl delete -f - --context=ctx-${CONTROL_PLANE_NAME}
kubectl delete -f ./multicluster-aware-gateway.yaml -n $ISTIO_NAMESPACE --context=ctx-${CONTROL_PLANE_NAME}
kubectl delete namespace/$ISTIO_NAMESPACE --context=ctx-${CONTROL_PLANE_NAME}


for DATA_PLANE in "${DATA_PLAINE_NAMES[@]}" ; do
    istioctl manifest generate -f ./.install/data-plane-$DATA_PLANE.yaml -n $ISTIO_NAMESPACE --context=ctx-$DATA_PLANE | kubectl delete -f - --context=ctx-${DATA_PLANE}
    kubectl delete namespace/$ISTIO_NAMESPACE --context=ctx-${DATA_PLANE}
done
