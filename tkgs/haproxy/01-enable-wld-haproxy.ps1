#Install-Module -Name VMware.WorkloadManagement
#Find-Module "VMware.PowerCLI" | Install-Module -Scope "CurrentUser" -AllowClobber
Import-Module VMware.PowerCLI
Import-Module VMware.WorkloadManagement
# ssh root@haproxy
# tail -f /var/log/cloud-init.log
# systemctl list-units --state failed
#  cat /etc/haproxy/server.crt
# openssl s_client -showcerts -connect haproxyaddress:5556 
$DiskFormat = "Thin"
$vc="vcsa-01.haas-421.pez.vmware.com"
$vc_user="administrator@vsphere.local"
$vc_password="pass"
Connect-VIServer -User $vc_user -Password $vc_password -Server $vc
$VMCluster = Get-Cluster  -Name "Cluster"
$ManagementVirtualNetwork = get-virtualnetwork "Management"
$cert=@"
-----BEGIN CERTIFICATE-----
MIIEJDCCAwygAwIBAgIJALebffIta2n5MA0GCSqGSIb3DQEBCwUAMG0xCzAJBgNV
BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRIwEAYDVQQHDAlQYWxvIEFsdG8x
...
KNV8bUyZmHlfKhtzOUSsqIVcO8Tk/gj58NQOKGMSLdJ9ufv86dTrBBZ7oIh0jlt6
fwwCcOZfR90=
-----END CERTIFICATE-----
"@

Get-Cluster $VMCluster | Enable-WMCluster `
       -SizeHint Tiny `
       -ManagementVirtualNetwork $ManagementVirtualNetwork `
       -ManagementNetworkMode StaticRange `
       -ManagementNetworkStartIPAddress "10.213.216.45" `
       -ManagementNetworkSubnetMask "255.255.255.0" `
       -ManagementNetworkGateway "10.213.216.1" `
       -ManagementNetworkAddressRangeSize 5 `
       -MasterDnsServerIPAddress @("10.192.2.10") `
       -MasterNtpServer @("ntp1.svc.pivotal.io") `
       -ServiceCIDR "10.96.0.0/24" `
       -EphemeralStoragePolicy "tanzu" `
       -ImageStoragePolicy "tanzu" `
       -MasterStoragePolicy "tanzu" `
       -MasterDnsSearchDomain "haas-421.pez.vmware.com" `
       -ContentLibrary "Kubernetes" `
       -HAProxyName "haproxy" `
       -HAProxyDataPlaneAddresses "10.213.216.8:5556" `
       -HAProxyUsername "admin" `
       -HAProxyPassword "pass" `
       -HAProxyAddressRanges "10.213.217.64-10.213.217.89" `
       -HAProxyServerCertificateChain $cert `
       -WorkerDnsServer "10.192.2.10" `
       -PrimaryWorkloadNetworkSpecification ( New-WMNamespaceNetworkSpec `
          -Name "network-1" `
          -Gateway "10.213.217.1" `
          -Subnet "255.255.255.0" `
          -AddressRanges "10.213.217.130-10.213.217.149" `
          -DistributedPortGroup "Workload" `
       )
