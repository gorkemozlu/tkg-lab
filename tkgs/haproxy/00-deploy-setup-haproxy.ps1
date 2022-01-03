#Install-Module -Name VMware.WorkloadManagement
#Find-Module "VMware.PowerCLI" | Install-Module -Scope "CurrentUser" -AllowClobber
# Set-PowerCLIConfiguration -InvalidCertificateAction Ignore
Import-Module VMware.PowerCLI
Import-Module VMware.WorkloadManagement
# https://github.com/haproxytech/vmware-haproxy/releases
$DiskFormat = "Thin"
$VMname = "haproxy-vm"
$ovfPath =  "/home/ubuntu/haproxy-v0.2.0.ova"
$vc="vcsa-01.haas-421.pez.vmware.com"
$vc_user="administrator@vsphere.local"
$vc_password="pass"
Connect-VIServer -User $vc_user -Password $vc_password -Server $vc
$vmhosts = Get-VMHost
$Cluster="Cluster"
$Datastore="LUN01"
$VMhost = $vmhosts[0]
$ovfConfig = Get-OvfConfiguration -Ovf $ovfPath

$ovfConfig.network.hostname.Value = "tanzu-haproxy-1.haas-421.pez.vmware.com"
$ovfConfig.network.nameservers.Value = "10.192.2.10"
$ovfConfig.network.management_ip.Value = "10.213.216.7/24"
$ovfConfig.network.management_gateway.Value = "10.213.216.1"
$ovfConfig.network.workload_ip.Value = "10.213.217.3/24"
$ovfConfig.network.workload_gateway.Value = "10.213.217.1"

$ovfConfig.appliance.ca_cert.Value = ""
$ovfConfig.appliance.ca_cert_key.Value = ""
$ovfConfig.DeploymentOption.Value = "default"

$ovfConfig.appliance.root_pwd.Value = "pass"
$ovfConfig.appliance.permit_root_login.Value = "True"

$ovfConfig.loadbalance.dataplane_port.Value = "5556"
$ovfConfig.loadbalance.haproxy_user.Value = "admin"
$ovfConfig.loadbalance.haproxy_pwd.Value = "pass"


$ovfConfig.loadbalance.service_ip_range.Value = "10.213.217.64/26"

$ovfConfig.NetworkMapping.Management.Value = "Management"     #This is the default VSS portgroup created at install time
$ovfConfig.NetworkMapping.Workload.Value = "Workload" #This is the portgroup created earlier
$ovfConfig.NetworkMapping.Frontend.Value = ""                 #Not used in this script



Import-VApp -Source $ovfpath -OvfConfiguration $ovfConfig -Name $VMName -VMHost $VMHost -Location $Cluster -Datastore $Datastore -DiskStorageFormat $DiskFormat -Confirm:$false
Start-VM (Get-VM $VMname) 
