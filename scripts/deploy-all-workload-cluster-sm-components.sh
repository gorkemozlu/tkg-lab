#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

# Workload Step 1
$TKG_LAB_SCRIPTS/deploy-workload-cluster.sh \
  $(yq e .workload-cluster-sm1.name $PARAMS_YAML) \
  $(yq e .workload-cluster-sm1.worker-replicas $PARAMS_YAML) \
  $(yq e .workload-cluster-sm1.controlplane-endpoint $PARAMS_YAML) \
  $(yq e '.shared-services-cluster.kubernetes-version // null' $PARAMS_YAML)
# Workload Step 2
$TKG_LAB_SCRIPTS/tmc-attach.sh $(yq e .workload-cluster-sm1.name $PARAMS_YAML)
# Workload Step 3
$TKG_LAB_SCRIPTS/tmc-policy.sh \
  $(yq e .workload-cluster-sm1.name $PARAMS_YAML) \
  cluster.admin \
  platform-team
# Workload Step 4
IAAS=$(yq e .iaas $PARAMS_YAML)
$TKG_LAB_SCRIPTS/deploy-cert-manager.sh $(yq e .workload-cluster-sm1.name $PARAMS_YAML)
$TKG_LAB_SCRIPTS/generate-and-apply-contour-yaml.sh $(yq e .workload-cluster-sm1.name $PARAMS_YAML)
$TKG_LAB_SCRIPTS/generate-and-apply-external-dns-yaml.sh $(yq e .workload-cluster-sm1.name $PARAMS_YAML)
$TKG_LAB_SCRIPTS/generate-and-apply-cluster-issuer-yaml.sh $(yq e .workload-cluster-sm1.name $PARAMS_YAML)
# Workload Step 6
$TKG_LAB_SCRIPTS/generate-and-apply-fluent-bit-yaml.sh $(yq e .workload-cluster-sm1.name $PARAMS_YAML)
# Workload Step 7
# $TKG_LAB_SCRIPTS/deploy-wavefront.sh $(yq e .workload-cluster-sm1.name $PARAMS_YAML)
$TKG_LAB_SCRIPTS/generate-and-apply-prometheus-yaml.sh \
  $(yq e .workload-cluster-sm1.name $PARAMS_YAML) \
  $(yq e .workload-cluster-sm1.prometheus-fqdn $PARAMS_YAML)
$TKG_LAB_SCRIPTS/generate-and-apply-grafana-yaml.sh \
  $(yq e .workload-cluster-sm1.name $PARAMS_YAML) \
  $(yq e .workload-cluster-sm1.grafana-fqdn $PARAMS_YAML)
# Workload Step 8
#$TKG_LAB_SCRIPTS/dataprotection.sh $(yq e .workload-cluster-sm1.name $PARAMS_YAML)
# Worload Step 9 - install acme
#$TKG_LAB_SCRIPTS/generate-and-apply-acme-wf.sh \
#  $(yq e .workload-cluster-sm1.name $PARAMS_YAML) \  
#  $(yq e .wavefront.api-key $PARAMS_YAML) \
#  $(yq e .wavefront.url $PARAMS_YAML) \
#  $(yq e .wavefront.jaeger-app-name-prefix $PARAMS_YAML) \
#  $(yq e .workload-cluster-sm1.sm-type $PARAMS_YAML)


#######################################################

# Workload Step 1
$TKG_LAB_SCRIPTS/deploy-workload-cluster.sh \
  $(yq e .workload-cluster-sm2.name $PARAMS_YAML) \
  $(yq e .workload-cluster-sm2.worker-replicas $PARAMS_YAML) \
  $(yq e .workload-cluster-sm2.controlplane-endpoint $PARAMS_YAML) \
  $(yq e '.shared-services-cluster.kubernetes-version // null' $PARAMS_YAML)
# Workload Step 2
$TKG_LAB_SCRIPTS/tmc-attach.sh $(yq e .workload-cluster-sm2.name $PARAMS_YAML)
# Workload Step 3
$TKG_LAB_SCRIPTS/tmc-policy.sh \
  $(yq e .workload-cluster-sm2.name $PARAMS_YAML) \
  cluster.admin \
  platform-team
# Workload Step 4
IAAS=$(yq e .iaas $PARAMS_YAML)
$TKG_LAB_SCRIPTS/deploy-cert-manager.sh $(yq e .workload-cluster-sm2.name $PARAMS_YAML)
$TKG_LAB_SCRIPTS/generate-and-apply-contour-yaml.sh $(yq e .workload-cluster-sm2.name $PARAMS_YAML)
$TKG_LAB_SCRIPTS/generate-and-apply-external-dns-yaml.sh $(yq e .workload-cluster-sm2.name $PARAMS_YAML)
$TKG_LAB_SCRIPTS/generate-and-apply-cluster-issuer-yaml.sh $(yq e .workload-cluster-sm2.name $PARAMS_YAML)
# Workload Step 6
$TKG_LAB_SCRIPTS/generate-and-apply-fluent-bit-yaml.sh $(yq e .workload-cluster-sm2.name $PARAMS_YAML)
# Workload Step 7
# $TKG_LAB_SCRIPTS/deploy-wavefront.sh $(yq e .workload-cluster-sm2.name $PARAMS_YAML)
$TKG_LAB_SCRIPTS/generate-and-apply-prometheus-yaml.sh \
  $(yq e .workload-cluster-sm2.name $PARAMS_YAML) \
  $(yq e .workload-cluster-sm2.prometheus-fqdn $PARAMS_YAML)
$TKG_LAB_SCRIPTS/generate-and-apply-grafana-yaml.sh \
  $(yq e .workload-cluster-sm2.name $PARAMS_YAML) \
  $(yq e .workload-cluster-sm2.grafana-fqdn $PARAMS_YAML)
# Workload Step 8
#$TKG_LAB_SCRIPTS/dataprotection.sh $(yq e .workload-cluster-sm2.name $PARAMS_YAML)
# Worload Step 9 - install acme
#$TKG_LAB_SCRIPTS/generate-and-apply-acme-wf.sh \
#  $(yq e .workload-cluster-sm1.name $PARAMS_YAML) \  
#  $(yq e .wavefront.api-key $PARAMS_YAML) \
#  $(yq e .wavefront.url $PARAMS_YAML) \
#  $(yq e .wavefront.jaeger-app-name-prefix $PARAMS_YAML) \
#  $(yq e .workload-cluster-sm1.sm-type $PARAMS_YAML)

