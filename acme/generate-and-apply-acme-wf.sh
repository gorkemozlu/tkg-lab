#!/bin/bash
TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/../scripts/set-env.sh

CLUSTER=$1
API_TOKEN=$2
WAVEFRONT_URL=$3
JAEGER_APP_NAME=$4
SM_TYPE=$5
ACME_FQDN=$6
$ORG_API_TOKEN="CHANGEMEAPITOKENBASE64VALUE"
$ORG_JAEGER_APP_NAME="gorkemo-acme-fitness"
$ORG_CLUSTER_TAG="gregoryan-tkg-wlc"
$ORG_ACME_FQDN="CHANGEMEACMEFQDN"
API_TOKEN=$(echo "API_TOKEN"|base64)
mkdir -p generated/$CLUSTER/acme/
cp acme/jaeger-wfproxy.yaml generated/$CLUSTER/acme/jaeger-wfproxy.yaml
#modify wavefront-api token at jaeger-wfproxy.yaml
sed -i -e "s~$ORG_API_TOKEN~$API_TOKEN~g" generated/$CLUSTER/acme/jaeger-wfproxy.yaml
#mofify traceJaegerApplicationName at jaeger-wfproxy.yaml
sed -i -e "s~$ORG_JAEGER_APP_NAME~$JAEGER_APP_NAME~g" generated/$CLUSTER/acme/jaeger-wfproxy.yaml
#modify jaeger-wfproxy.yaml - configmap - cluster-span-tag value
sed -i -e "s~$ORG_CLUSTER_TAG~$CLUSTER~g" generated/$CLUSTER/acme/jaeger-wfproxy.yaml

#apply wavefront

if [ $SM_TYPE = "frontend" ];
then
  tanzu cluster kubeconfig get $CLUSTER --admin
  kubectl config use-context $CLUSTER-admin@$CLUSTER
  cp acme/fe.yaml generated/$CLUSTER/acme/fe.yaml
  cp acme/fe-tsm.yaml generated/$CLUSTER/acme/fe-tsm.yaml
  kubectl create ns acme-gns
  kubectl apply -f generated/$CLUSTER/acme/fe.yaml
  #modify fe-tsm.yaml - ingress url
  sed -i -e "s~$ORG_ACME_FQDN~$ACME_FQDN~g" generated/$CLUSTER/acme/fe-tsm.yaml
  kubectl apply -f generated/$CLUSTER/acme/fe-tsm.yaml
  kubectl apply -f generated/$CLUSTER/acme/jaeger-wfproxy.yaml
fi

if [ $SM_TYPE = "backend" ];
then
  tanzu cluster kubeconfig get $CLUSTER --admin
  kubectl config use-context $CLUSTER-admin@$CLUSTER
  kubectl create ns acme-gns
  cp acme/be.yaml generated/$CLUSTER/acme/be.yaml
  kubectl apply -f generated/$CLUSTER/acme/be.yaml
  kubectl apply -f generated/$CLUSTER/acme/jaeger-wfproxy.yaml
fi


locust --host=https://${ACME_FQDN}