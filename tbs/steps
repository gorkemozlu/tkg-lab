#!/bin/bash
TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh
if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name as args"
  exit 1
fi
CLUSTER_NAME=$1
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
#docker login harbor.dorn.gorke.ml
#docker login registry.tanzu.vmware.com
imgpkg copy -b $(yq e .tbs.source-url-version $PARAMS_YAML) --to-repo $(yq e .tbs.harbor-path $PARAMS_YAML)
imgpkg pull -b $(yq e .tbs.harbor-path-and-version $PARAMS_YAML) -o /tmp/bundle/

ytt -f /tmp/bundle/values.yaml \
    -f /tmp/bundle/config/ \
        -v kp_default_repository=$(yq e .tbs.harbor-path $PARAMS_YAML) \
        -v kp_default_repository_username='admin' \
        -v kp_default_repository_password=$(yq e .tbs.harbor-pass $PARAMS_YAML) \
        -v pull_from_kp_default_repo=true \
        -v tanzunet_username=$(yq e .tbs.tanzunet-user $PARAMS_YAML) \
        -v tanzunet_password=$(yq e .tbs.tanzunet-pass $PARAMS_YAML) \
        | kbld -f /tmp/bundle/.imgpkg/images.yml -f- \
        | kapp deploy -a tanzu-build-service -f- -y

kp clusterbuilder list