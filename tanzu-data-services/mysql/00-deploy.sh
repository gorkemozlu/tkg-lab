#!/bin/bash

export HELM_EXPERIMENTAL_OCI=1
export ORG_OPERATOR_IMAGE=$(yq e .operatorImage v1.2.0/tanzu-sql-with-mysql-operator/values.yaml)
export ORG_INSTANCE_IMAGE="registry.tanzu.vmware.com/tanzu-mysql-for-kubernetes/tanzu-mysql-instance:1.2.0"
export ORG_REGISTRY=$(yq e .registry v1.2.0/tanzu-sql-with-mysql-operator/values.yaml)
export HARBOR_OPERATOR_IMAGE="harbor.dorn.gorke.ml/tanzu-sql-mysql/tanzu-mysql-operator"
export HARBOR_OPERATOR_IMAGE_TAG="harbor.dorn.gorke.ml/tanzu-sql-mysql/tanzu-mysql-operator:1.2.0"
export HARBOR_INSTANCE_IMAGE="harbor.dorn.gorke.ml/tanzu-sql-mysql/tanzu-mysql-instance"
export HARBOR_REGISTRY="harbor.dorn.gorke.ml/tanzu-sql-mysql/"
export HARBOR_REG_CRED="harbor-registry-credentials"
helm registry login registry.pivotal.io \
  --username=gorkemo@vmware.com \
  --password=pass

kubectl create secret docker-registry $HARBOR_REG_CRED \
    --docker-server=${HARBOR_URL} \
    --docker-username=${HARBOR_USER} \
    --docker-password="${HARBOR_PASSWORD}"

helm chart pull registry.tanzu.vmware.com/tanzu-mysql-for-kubernetes/tanzu-mysql-operator-chart:1.2.0
mkdir v1.2.0
helm chart export registry.tanzu.vmware.com/tanzu-mysql-for-kubernetes/tanzu-mysql-operator-chart:1.2.0 --destination=./v1.2.0



cp v1.2.0/tanzu-sql-with-mysql-operator/values.yaml v1.2.0/tanzu-sql-with-mysql-operator/operator-values-override.yaml
imgpkg copy -i $ORG_OPERATOR_IMAGE --to-repo harbor.dorn.gorke.ml/tanzu-sql-mysql/tanzu-mysql-operator
imgpkg copy -i $ORG_INSTANCE_IMAGE --to-repo harbor.dorn.gorke.ml/tanzu-sql-mysql/tanzu-mysql-instance

sed -i -e "s~$ORG_OPERATOR_IMAGE~$HARBOR_OPERATOR_IMAGE_TAG~g" v1.2.0/tanzu-sql-with-mysql-operator/operator-values-override.yaml
sed -i -e "s~$ORG_REGISTRY~$HARBOR_REGISTRY~g" v1.2.0/tanzu-sql-with-mysql-operator/operator-values-override.yaml
sed -i -e "s~tanzu-image-registry~$HARBOR_REG_CRED~g" v1.2.0/tanzu-sql-with-mysql-operator/operator-values-override.yaml
# modify values-override with sed

helm install --wait --values=./v1.2.0/tanzu-sql-with-mysql-operator/operator-values-override.yaml tanzu-sql-with-mysql-operator ./v1.2.0/tanzu-sql-with-mysql-operator


#mysql -uroot -pQTtCOCA47boWSLbwOQq6kjqY1qKl
#ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
# CREATE USER 'tanzu'@'100.96.2.1' IDENTIFIED BY 'password';
# GRANT ALL PRIVILEGES ON *.* TO 'tanzu'@'100.96.2.1' WITH GRANT OPTION;
# flush privileges;