#!/bin/bash


# prepare config wuth 3 contexts:
    # control
    # remote 1
    # remote 2

CONTROL_PLANE_CTX=$1
DATA_PLAINE_CTXS=$2


rm -rf ./.install && mkdir ./.install
cp ./control-plane.yaml ./.install/control-plane.yaml

DATA_PLAINE_NAMES=(${DATA_PLAINE_CTXS//,/ })
for DATA_PLANE in "${DATA_PLAINE_NAMES[@]}" ; do
    sed "s/DATA_PLANE_NAME/$DATA_PLANE/" ./data-plane-fragment.yaml >> ./.install/control-plane.yaml
done

istioctl manifest install ./.install/control-plane.yaml --context=${CONTROL_PLANE_CTX}
kubectl rollout status deploy/-ingressgateway --context=${CONTROL_PLANE_CTX}
kubectl apply -f gateway.yaml --context=${CONTROL_PLANE_CTX}
ISTIOD_REMOTE_EP=$(kubectl get svc -ingressgateway -n -system --context=${CONTROL_PLANE_CTX} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

for DATA_PLANE in "${DATA_PLAINE_NAMES[@]}" ; do
    sed "s/ISTIOD_REMOTE_EP/$ISTIOD_REMOTE_EP/" ./data-plane.yaml | sed "s/DATA_PLANE_NAME/$DATA_PLANE/" > ./.install/data-plne-$DATA_PLANE.yaml

    istioctl manifest install ./.install/data-plne-$DATA_PLANE.yaml --context=${DATA_PLANE}
    kubectl rollout status deploy/-ingressgateway --context=${DATA_PLANE}
    
    kubectl apply -f gateway.yaml --context=${DATA_PLANE}
    istioctl x create-remote-secret --name ${DATA_PLANE} --context=${DATA_PLANE} | \
        kubectl apply -f - --context=${CONTROL_PLANE_CTX}
done








