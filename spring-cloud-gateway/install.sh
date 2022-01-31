#!/bin/bash

pivnet download-product-files --product-slug='spring-cloud-gateway-for-kubernetes' --release-version='1.0.8' --product-file-id=1124614

tar -xvf spring-cloud-gateway-k8s-1.0.8.tgz

cd spring-cloud-gateway-k8s-1.0.8

./scripts/relocate-images.sh harbor.dorn.gorke.ml/spring-cloud-gateway

kubectl create ns spring-cloud-gateway

./scripts/install-spring-cloud-gateway.sh