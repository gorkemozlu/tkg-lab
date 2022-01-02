#Install-Module -Name VMware.WorkloadManagement
#Find-Module "VMware.PowerCLI" | Install-Module -Scope "CurrentUser" -AllowClobber
#Import-Module VMware.PowerCLI
#Import-Module VMware.WorkloadManagement
# ssh root@haproxy
# tail -f /var/log/cloud-init.log
# systemctl list-units --state failed
#  cat /etc/haproxy/server.crt
$DiskFormat = "Thin"                                                                                                                                                                  $VMname = "haproxy"                                                                                                                                                                    $ovfPath =  "/home/ubuntu/haproxy-v0.2.0.ova"                                                                                                                                          
$vc="vcsa-01.haas-509.pez.vmware.com"
$vc_user="administrator@vsphere.local"
$vc_password="pass"
Connect-VIServer -User $vc_user -Password $vc_password -Server $vc
$VMCluster = Get-Cluster  -Name "Cluster"
$ManagementVirtualNetwork = get-virtualnetwork "Management"
$cert=@"
-----BEGIN CERTIFICATE-----
MIIEJTCCAw2gAwIBAgIJAMyB66+etq5eMA0GCSqGSIb3DQEBCwUAMG4xCzAJBgNV
...
9mmxp+6dlDvYU817Im68+S7UchoPS2PW1Kn9JXLxFk7xUlCvlKC1OFCyLwOzCqVv
Gj9VwwMkqzcf
-----END CERTIFICATE-----
"@

Get-Cluster $VMCluster | Enable-WMCluster `
       -SizeHint Tiny `
       -ManagementVirtualNetwork $ManagementVirtualNetwork `
       -ManagementNetworkMode StaticRange `
       -ManagementNetworkGateway "10.212.160.1" `
       -ManagementNetworkSubnetMask "255.255.255.0" `
       -ManagementNetworkStartIPAddress "10.212.160.45" `
       -ManagementNetworkAddressRangeSize 5 `
       -MasterDnsServerIPAddress @("10.192.2.10") `
       -MasterNtpServer @("ntp1.svc.pivotal.io") `
       -ServiceCIDR "10.96.0.0/24" `
       -EphemeralStoragePolicy "tanzu" `
       -ImageStoragePolicy "tanzu" `
       -MasterStoragePolicy "tanzu" `
       -MasterDnsSearchDomain "haas-509.pez.vmware.com" `
       -ContentLibrary "Kubernetes" `
       -HAProxyName "haproxy" `
       -HAProxyAddressRanges "10.212.161.128-10.212.161.160" `
       -HAProxyUsername "admin" `
       -HAProxyPassword "vmware" `
       -HAProxyDataPlaneAddresses "10.212.160.65:5556" `
       -HAProxyServerCertificateChain $cert `
       -WorkerDnsServer "10.192.2.10" `
       -PrimaryWorkloadNetworkSpecification ( New-WMNamespaceNetworkSpec `
          -Name "network-1" `
          -Gateway "10.212.161.1" `
          -Subnet "255.255.255.0" `
          -AddressRanges "10.212.161.180-10.212.161.200" `
          -DistributedPortGroup "Workload" `
       )
