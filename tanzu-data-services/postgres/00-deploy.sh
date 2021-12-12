#!/bin/bash

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh
if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name as args"
  exit 1
fi

CLUSTER_NAME=$1
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

export HELM_EXPERIMENTAL_OCI=1

helm registry login registry.pivotal.io \
  --username=$(yq e .tanzu-net.user $PARAMS_YAML) \
  --password=$(yq e .tanzu-net.pass $PARAMS_YAML)

#kubectl create secret docker-registry regsecret \
#    --docker-server=${HARBOR_URL} \
#    --docker-username=${HARBOR_USER} \
#    --docker-password="${HARBOR_PASSWORD}"

helm chart pull $(yq e .tanzu-data-services.postgres.chart $PARAMS_YAML)

helm chart export $(yq e .tanzu-data-services.postgres.chart $PARAMS_YAML) --destination=./v1.4.0

imgpkg copy -i $(yq e .tanzu-data-services.postgres.operator-tanzu-img $PARAMS_YAML) --to-repo $(yq e .tanzu-data-services.operator-internal-img $PARAMS_YAML)
imgpkg copy -i $(yq e .tanzu-data-services.postgres.instance-tanzu-img $PARAMS_YAML) --to-repo $(yq e .tanzu-data-services.instance-internal-img $PARAMS_YAML)

cp v1.4.0/postgres-operator/values.yaml v1.4.0/postgres-operator/operator-values-override.yaml

# modify values-override with sed

helm install --wait --values=./v1.4.0/postgres-operator/operator-values-override.yaml my-postgres-operator ./v1.4.0/postgres-operator


#kubectl apply -f 01-backuplocation.yaml
#kubectl apply -f 02-pg-instance.yaml
#kubectl cp tanzu-sql-postgres/pg_hba.conf postgres-sample-0:/pgsql/data/pg_hba.conf -n default
#kubectl delete pod pod-name
#dbname=$(kubectl get secret postgres-sample-db-secret -o go-template='{{.data.dbname | base64decode}}')
#username=$(kubectl get secret postgres-sample-db-secret -o go-template='{{.data.username | base64decode}}')
#password=$(kubectl get secret postgres-sample-db-secret -o go-template='{{.data.password | base64decode}}')
#host=$(kubectl get service postgres-sample -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
#port=$(kubectl get service postgres-sample -o jsonpath='{.spec.ports[0].port}')
#kubectl apply -f 03-backup.yaml
#kubectl apply -f 04-restore.yaml

#kubectl get events --field-selector involvedObject.name=backup-sample
#kubectl get events --field-selector involvedObject.name=restore-test
#todo # add prometheus metrics
