#!/bin/bash

rm -rf ~/Library/Application\ Support/tanzu-cli
rm -rf cli/
tar -xvf tanzu-cli-bundle-darwin-amd64.tar
gunzip kubectl-mac-v1.21.2+vmware.1.gz
install kubectl-mac-v1.21.2+vmware.1 /usr/local/bin/kubectl
gunzip cli/*.gz
sudo install cli/core/v1.4.0/tanzu-core-darwin_amd64 /usr/local/bin/tanzu
#chmod ugo+x cli/ytt-darwin-amd64-v0.34.0+vmware.1
#cp cli/ytt-darwin-amd64-v0.34.0+vmware.1 /usr/local/bin/ytt
#chmod ugo+x cli/kapp-darwin-amd64-v0.37.0+vmware.1
#cp cli/kapp-darwin-amd64-v0.37.0+vmware.1 /usr/local/bin/kapp
#cp cli/kbld-darwin-amd64-v0.30.0+vmware.1 /usr/local/bin/kbld
#chmod ugo+x cli/imgpkg-darwin-amd64-v0.10.0+vmware.1
#cp cli/imgpkg-darwin-amd64-v0.10.0+vmware.1 /usr/local/bin/imgpkg
tanzu plugin clean
tanzu plugin install --local cli all
tanzu version
tanzu plugin list