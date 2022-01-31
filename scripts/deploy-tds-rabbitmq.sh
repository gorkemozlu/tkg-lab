#!/bin/bash

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh
if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name as args"
  exit 1
fi

CLUSTER_NAME=$1
ORG_TOKEN="CHANGEMEAUTHBASE64"
ORG_BUNDLE_URL="CHANGEMEBUNDLEURL"
ORG_VERSION="CHANGEMEVERSION"
ORG_SA="CHANGEMESERVICEACCOUNT"
TOKEN=$(yq e .tanzu-data-services.rabbitmq.token $PARAMS_YAML)
BUNDLE_URL=$(yq e '.tanzu-data-services.rabbitmq.harbor-path +":"+ .tanzu-data-services.rabbitmq.version' $PARAMS_YAML)
VERSION=$(yq e .tanzu-data-services.rabbitmq.version $PARAMS_YAML)
SA_NAME=$(yq e .tanzu-data-services.rabbitmq.sa-name $PARAMS_YAML)
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

# docker login https://registry.tanzu.vmware.com
imgpkg copy -b $(yq e .tanzu-data-services.rabbitmq.bundle $PARAMS_YAML)  --to-repo $(yq e .tanzu-data-services.rabbitmq.harbor-path $PARAMS_YAML)

kubectl create ns secretgen-controller
kubectl apply -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/download/v0.7.1/release.yml
mkdir -p generated/$CLUSTER_NAME/rabbitmq/
cp tanzu-data-services/rabbitmq/01-secret.yaml generated/$CLUSTER_NAME/rabbitmq/01-secret.yaml
cp tanzu-data-services/rabbitmq/02-package-repo.yaml generated/$CLUSTER_NAME/rabbitmq/02-package-repo.yaml
cp tanzu-data-services/rabbitmq/03-package-install.yaml generated/$CLUSTER_NAME/rabbitmq/03-package-install.yaml
cp tanzu-data-services/rabbitmq/03-package-install.yaml generated/$CLUSTER_NAME/rabbitmq/03-package-install.yaml

sed -i -e "s~$ORG_TOKEN~$TOKEN~g" generated/$CLUSTER_NAME/rabbitmq/01-secret.yaml
sed -i -e "s~$ORG_BUNDLE_URL~$BUNDLE_URL~g" generated/$CLUSTER_NAME/rabbitmq/02-package-repo.yaml
sed -i -e "s~$ORG_VERSION~$VERSION~g" generated/$CLUSTER_NAME/rabbitmq/03-package-install.yaml
sed -i -e "s~$ORG_SA~$SA_NAME~g" generated/$CLUSTER_NAME/rabbitmq/03-package-install.yaml

kubectl apply -f generated/$CLUSTER_NAME/rabbitmq/01-secret.yaml
kapp deploy -a tanzu-rabbitmq-repo -f generated/$CLUSTER_NAME/rabbitmq/02-package-repo.yaml
kubectl create sa $(yq e .tanzu-data-services.rabbitmq.sa-name $PARAMS_YAML)
kubectl create clusterrolebinding azdevops-clusterrolebinding --clusterrole=cluster-admin --serviceaccount=default:$(yq e .tanzu-data-services.rabbitmq.sa-name $PARAMS_YAML)
kapp deploy -a tanzu-rabbitmq -f generated/$CLUSTER_NAME/rabbitmq/03-package-install.yaml
#kubectl apply -f 04-rmbq.yaml