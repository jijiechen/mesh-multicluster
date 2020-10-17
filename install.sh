#!/bin/bash

set -e
set -x 

# prepare config wuth 3 contexts:
    # control
    # remote 1
    # remote 2

CONTROL_PLANE_CTX=$1
DATA_PLAINE_CTXS=$2

ISTIO_NAMESPACE=istio-system
DATA_PLAINE_NAMES=(${DATA_PLAINE_CTXS//,/ })


rm -rf ./.install && mkdir ./.install
cp ./control-plane.yaml ./.install/control-plane.yaml

for DATA_PLANE in "${DATA_PLAINE_NAMES[@]}" ; do
    sed "s/DATA_PLANE_NAME/$DATA_PLANE/" ./data-plane-fragment.yaml >> ./.install/control-plane.yaml
done
istioctl install -f ./.install/control-plane.yaml -n $ISTIO_NAMESPACE --context=ctx-${CONTROL_PLANE_CTX}
kubectl apply -f ./multicluster-aware-gateway.yaml -n $ISTIO_NAMESPACE --context=ctx-${CONTROL_PLANE_CTX}

ISTIOD_REMOTE_EP=
until [ ! -z "$ISTIOD_REMOTE_EP" ] ; do
    echo "Trying to get a public IP for ingressgateway at ctx-${CONTROL_PLANE_CTX}..."
    ISTIOD_REMOTE_EP=$(kubectl get svc istio-ingressgateway -n $ISTIO_NAMESPACE --context=ctx-${CONTROL_PLANE_CTX} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    sleep 1.5;
done

for DATA_PLANE in "${DATA_PLAINE_NAMES[@]}" ; do
    sed "s/ISTIOD_REMOTE_EP/$ISTIOD_REMOTE_EP/" ./data-plane.yaml | sed "s/DATA_PLANE_NAME/$DATA_PLANE/" > ./.install/data-plne-$DATA_PLANE.yaml

    kubectl apply -f ./.install/control-plane-ca-cm.yaml -n $ISTIO_NAMESPACE --context=ctx-${DATA_PLANE}
    istioctl install -f ./.install/data-plne-$DATA_PLANE.yaml -n $ISTIO_NAMESPACE --context=ctx-${DATA_PLANE}
    
    kubectl apply -f ./multicluster-aware-gateway.yaml -n $ISTIO_NAMESPACE --context=ctx-${DATA_PLANE} 
    istioctl x create-remote-secret --name ${DATA_PLANE} -n $ISTIO_NAMESPACE --context=ctx-${DATA_PLANE} | \
        kubectl apply -n $ISTIO_NAMESPACE --context=ctx-${CONTROL_PLANE_CTX} -f -
done


 