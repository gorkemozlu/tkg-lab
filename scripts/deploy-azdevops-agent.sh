#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

IAAS=$(yq e .iaas $PARAMS_YAML)

export CLUSTER=$1
export TOKEN=$2
export URL=$3
ORG_TOKEN="CHANGEMETOKEN"
ORG_URL="CHANGEMEURL"
# Retrive admin kubeconfig
tanzu cluster kubeconfig get $CLUSTER --admin

kubectl config use-context $CLUSTER-admin@$CLUSTER

mkdir -p generated/$CLUSTER/azdevops
sed -i -e "s~$ORG_TOKEN~$TOKEN~g" generated/$CLUSTER/azdevops/agent.yaml
sed -i -e "s~$ORG_URL~$URL~g" generated/$CLUSTER/azdevops/agent.yaml
# Apply agent
kubectl apply -f generated/$CLUSTER/azdevops/agent.yaml

# Apply kpack
#kubectl apply -f https://github.com/pivotal/kpack/releases/download/v0.4.0/release-0.4.0.yaml

#kubectl create sa azdevops
#kubectl create clusterrolebinding azdevops-clusterrolebinding --clusterrole=cluster-admin --serviceaccount=default:azdevops
SERVERURL=$(kubectl config view --minify -o json|jq ."clusters"|jq '.[]'|jq ."cluster"|jq ."server" -r)
SECRETNAME=$(kubectl get sa azdevops -o json|jq ."secrets"|jq '.[]'|jq ."name" -r)

kubectl get secret ${SECRETNAME} -o json
echo ""
echo $SERVERURL
