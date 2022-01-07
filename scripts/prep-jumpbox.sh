#!/bin/bash
wget https://10.213.217.64/wcp/plugin/linux-amd64/vsphere-plugin.zip --no-check-certificate
sudo apt install unzip -y
unzip vsphere-plugin.zip 
sudo cp bin/kubectl /usr/bin/
sudo cp bin/kubectl-vsphere /usr/bin/
wget https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx_v0.9.4_linux_x86_64.tar.gz
tar -xvf kubectx_v0.9.4_linux_x86_64.tar.gz 
sudo cp kubectx /usr/bin/
wget https://github.com/PowerShell/PowerShell/releases/download/v7.1.5/powershell_7.1.5-1.ubuntu.18.04_amd64.deb
sudo dpkg -i powershell_7.1.5-1.ubuntu.18.04_amd64.deb 
sudo apt install -f
sudo dpkg -i powershell_7.1.5-1.ubuntu.18.04_amd64.deb
wget https://github.com/vmware-tanzu/octant/releases/download/v0.25.0/octant_0.25.0_Linux-64bit.tar.gz
tar -xvf octant_0.25.0_Linux-64bit.tar.gz
sudo cp octant_0.25.0_Linux-64bit/octant /usr/bin/
wget https://github.com/wercker/stern/releases/download/1.11.0/stern_linux_amd64
chmod +x stern_linux_amd64
sudo cp stern_linux_amd64 /usr/bin/stern
#pwsh
#Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
#Install-Module -Name VMware.WorkloadManagement
#Find-Module "VMware.PowerCLI" | Install-Module -Scope "CurrentUser" -AllowClobber