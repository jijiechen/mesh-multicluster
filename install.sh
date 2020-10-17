#!/bin/bash

set -e

# prepare config wuth 3 contexts:
    # control
    # remote 1
    # remote 2

# import cacert manually

CONTROL_PLANE_NAME=$1
DATA_PLAINE_CTXS=$2

ISTIO_NAMESPACE=istio-system
DATA_PLAINE_NAMES=(${DATA_PLAINE_CTXS//,/ })


rm -rf ./.install && mkdir ./.install
cp ./control-plane.yaml ./.install/control-plane.yaml

kubectl create namespace $ISTIO_NAMESPACE  --context=ctx-$CONTROL_PLANE_NAME || true
for DATA_PLANE in "${DATA_PLAINE_NAMES[@]}" ; do
    sed "s/DATA_PLANE_NAME/$DATA_PLANE/" ./data-plane-fragment.yaml >> ./.install/control-plane.yaml
done
istioctl install -f ./.install/control-plane.yaml -n $ISTIO_NAMESPACE --context=ctx-${CONTROL_PLANE_NAME}
kubectl apply -f ./multicluster-aware-gateway.yaml -n $ISTIO_NAMESPACE --context=ctx-${CONTROL_PLANE_NAME}




ISTIOD_REMOTE_EP=
until [ ! -z "$ISTIOD_REMOTE_EP" ] ; do
    sleep 1.5;
    echo "Trying to get a public IP for ingressgateway at ctx-${CONTROL_PLANE_NAME}..."
    ISTIOD_REMOTE_EP=$(kubectl get svc/istio-ingressgateway -n $ISTIO_NAMESPACE --context=ctx-${CONTROL_PLANE_NAME} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
done

for DATA_PLANE in "${DATA_PLAINE_NAMES[@]}" ; do
    echo "Installing cluster $DATA_PLANE..."
    sed "s/ISTIOD_REMOTE_EP/$ISTIOD_REMOTE_EP/" ./data-plane.yaml | sed "s/DATA_PLANE_NAME/$DATA_PLANE/" > ./.install/data-plane-$DATA_PLANE.yaml
    kubectl create namespace $ISTIO_NAMESPACE --context=ctx-$DATA_PLANE || true

    sleep 2
    ./install-helper.sh $DATA_PLANE $CONTROL_PLANE_NAME $ISTIO_NAMESPACE &
    istioctl install -f ./.install/data-plane-$DATA_PLANE.yaml -n $ISTIO_NAMESPACE --context=ctx-$DATA_PLANE
    kubectl apply -f ./multicluster-aware-gateway.yaml -n $ISTIO_NAMESPACE --context=ctx-${DATA_PLANE} 
done

