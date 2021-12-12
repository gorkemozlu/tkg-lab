#!/bin/bash

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export CLUSTER=$1
export HELM_EXPERIMENTAL_OCI=1
export VERSION=$(yq e .tanzu-data-services.mysql.version $PARAMS_YAML)
export ORG_OPERATOR_IMAGE=$(yq e .tanzu-data-services.mysql.operator-tanzu-img $PARAMS_YAML)
export ORG_INSTANCE_IMAGE=$(yq e .tanzu-data-services.mysql.instance-tanzu-img $PARAMS_YAML)

export HARBOR_OPERATOR_IMAGE=$(yq e .tanzu-data-services.mysql.operator-internal-img $PARAMS_YAML)
export HARBOR_OPERATOR_IMAGE_TAG=$(yq e .tanzu-data-services.mysql.operator-internal-img $PARAMS_YAML):1.2.0
export HARBOR_INSTANCE_IMAGE=$(yq e .tanzu-data-services.mysql.instance-internal-img $PARAMS_YAML)
export HARBOR_REGISTRY=$(yq e .tanzu-data-services.mysql.harbor-path $PARAMS_YAML)
export HARBOR_REG_CRED=$(yq e .tanzu-data-services.mysql.harbor-secret-name $PARAMS_YAML)


helm registry login registry.pivotal.io \
  --username=$(yq e .tanzu-net.user $PARAMS_YAML) \
  --password=$(yq e .tanzu-net.pass $PARAMS_YAML)


tanzu cluster kubeconfig get $CLUSTER --admin

kubectl config use-context $CLUSTER-admin@$CLUSTER

kubectl create secret docker-registry $HARBOR_REG_CRED \
    --docker-server=${HARBOR_URL} \
    --docker-username=${HARBOR_USER} \
    --docker-password="${HARBOR_PASSWORD}"

helm chart pull $(yq e .tanzu-data-services.mysql.chart $PARAMS_YAML)
mkdir $VERSION
helm chart export $(yq e .tanzu-data-services.mysql.chart $PARAMS_YAML) --destination=./$VERSION

export ORG_REGISTRY=$(yq e .registry $VERSION/tanzu-sql-with-mysql-operator/values.yaml)

cp $VERSION/tanzu-sql-with-mysql-operator/values.yaml $VERSION/tanzu-sql-with-mysql-operator/operator-values-override.yaml
imgpkg copy -i $ORG_OPERATOR_IMAGE --to-repo $(yq e .tanzu-data-services.mysql.operator-internal-img $PARAMS_YAML)
imgpkg copy -i $ORG_INSTANCE_IMAGE --to-repo $(yq e .tanzu-data-services.mysql.instance-internal-img $PARAMS_YAML)

sed -i -e "s~$ORG_OPERATOR_IMAGE~$HARBOR_OPERATOR_IMAGE_TAG~g" $VERSION/tanzu-sql-with-mysql-operator/operator-values-override.yaml
sed -i -e "s~$ORG_REGISTRY~$HARBOR_REGISTRY~g" $VERSION/tanzu-sql-with-mysql-operator/operator-values-override.yaml
sed -i -e "s~tanzu-image-registry~$HARBOR_REG_CRED~g" $VERSION/tanzu-sql-with-mysql-operator/operator-values-override.yaml
# modify values-override with sed

helm install --wait --values=./$VERSION/tanzu-sql-with-mysql-operator/operator-values-override.yaml tanzu-sql-with-mysql-operator ./$VERSION/tanzu-sql-with-mysql-operator


#mysql -uroot -pQTtCOCA47boWSLbwOQq6kjqY1qKl
#ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
# CREATE USER 'tanzu'@'100.96.2.1' IDENTIFIED BY 'password';
# GRANT ALL PRIVILEGES ON *.* TO 'tanzu'@'100.96.2.1' WITH GRANT OPTION;
# flush privileges;