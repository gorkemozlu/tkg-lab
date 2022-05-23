#!/bin/bash

pivnet download-product-files --product-slug='spring-cloud-gateway-for-kubernetes' --release-version='1.1.1' --product-file-id=1221512

tar -xvf spring-cloud-gateway-k8s-1.1.1.tgz

cd spring-cloud-gateway-k8s-1.1.1

./scripts/relocate-images.sh harbor.dorn.gorke.ml/spring-cloud-gateway

kubectl create ns spring-cloud-gateway

./scripts/install-spring-cloud-gateway.sh