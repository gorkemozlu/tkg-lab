#!/bin/bash
TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

TMC_URL="$(yq e .tmc.url $PARAMS_YAML)"
CSP_TOKEN="$(yq e .tmc.csp-token $PARAMS_YAML)"
ELASTIC_URL="$(yq e .shared-services-cluster.elasticsearch-fqdn $PARAMS_YAML)"
echo $TMC_URL
echo $CSP_TOKEN

wget https://github.com/warroyo/tmc-telegraf-input/releases/download/v0.1.0/tmcevents-linux-amd64.tar.gz
mkdir /var/lib/telegraf
tar xf tmcevents-linux-amd64.tar.gz -C /var/lib/telegraf
rm /var/lib/telegraf/tmcevents-linux-amd64/tmcevents.conf

cat <<EOF | tee /var/lib/telegraf/tmcevents-linux-amd64/tmcevents.conf
[[inputs.tmcevents]]
  #hostname for your tmc org
  tmc_hostname = "${TMC_URL}"


  #optional defaults to console.cloud.vmware.com
  #csp_hostname = ""

  #token from your csp org
  csp_token = "${CSP_TOKEN}"


  #filter on specific event types
  # com.vmware.tmc.cluster
  # com.vmware.tmc.cluster.health
  # com.vmware.tmc.cluster.lifecycle
  # com.vmware.tmc.clustergroup
  # com.vmware.tmc.namespace
  # com.vmware.tmc.provisioner
  # com.vmware.tmc.workspace
  # events = [
  #   "com.vmware.tmc.cluster",
  #   "com.vmware.tmc.cluster.health"
  # ]
EOF

cat <<EOF | tee /etc/apt/sources.list.d/influxdata.list
deb https://repos.influxdata.com/ubuntu bionic stable
EOF
curl -sL https://repos.influxdata.com/influxdb.key | apt-key add -
apt-get update
apt-get -y install telegraf


cat <<EOF | tee /etc/telegraf/telegraf.conf
[global_tags]
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  hostname = ""
  omit_hostname = false


[[outputs.elasticsearch]]
  urls = [ "http://${ELASTIC_URL}" ]
  timeout = "5s"
  enable_sniffer = false
  health_check_interval = "10s"
  index_name = "telegraf-%Y.%m.%d"
  manage_template = true
  template_name = "telegraf"
  overwrite_template = false
  force_document_id = false

[[inputs.execd]]
  command = ["/var/lib/telegraf/tmcevents-linux-amd64/tmcevents", "--config", "/var/lib/telegraf/tmcevents-linux-amd64/tmcevents.conf"]
  signal = "STDIN"
EOF

systemctl enable --now telegraf
systemctl start telegraf
systemctl is-enabled telegraf
systemctl status telegraf