#!/bin/bash

#flux delete  kustomization acme-fitness-frontend

flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --owner=gorkemozlu \
  --repository=flux-image-updates \
  --branch=main \
  --path=clusters/essos \
  --read-write-key \
  --personal