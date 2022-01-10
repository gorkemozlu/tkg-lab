#!/bin/bash
#https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/0.4/tap/GUID-install-general.html#prereqs
rm -rf ~/Library/Application\ Support/tanzu-cli
#tar -xvf tanzu-framework-darwin-amd64.tar
mkdir ~/Library/Application\ Support/tanzu-cli
sudo install cli/core/v0.12.0/tanzu-core-darwin_amd64 /usr/local/bin/tanzu
export TANZU_CLI_NO_INIT=true
tanzu config set features.global.context-aware-cli-for-plugins false
tanzu plugin install --local cli all
#tanzu plugin install secret --local ./cli
#tanzu plugin install accelerator --local ./cli
#tanzu plugin install apps --local ./cli
#tanzu plugin install package --local ./cli
#tanzu plugin install services --local ./cli
tanzu version
tanzu plugin list