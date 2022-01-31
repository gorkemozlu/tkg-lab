#!/bin/bash

rm -rf ~/Library/Application\ Support/tanzu-cli
sudo rm /usr/local/bin/tanzu
sudo install cli/core/v1.4.1/tanzu-core-darwin_amd64 /usr/local/bin/tanzu
tanzu plugin clean
tanzu plugin install --local cli all
tanzu version
tanzu plugin list