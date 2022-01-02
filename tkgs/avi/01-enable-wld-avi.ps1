
#Install-Module -Name VMware.WorkloadManagement
#Find-Module "VMware.PowerCLI" | Install-Module -Scope "CurrentUser" -AllowClobber
#Import-Module VMware.PowerCLI
#Import-Module VMware.WorkloadManagement
$vc="vcsa-01.haas-509.pez.vmware.com"
$vc_user="administrator@vsphere.local"
$vc_password="pass"
Connect-VIServer -User $vc_user -Password $vc_password -Server $vc
$VMCluster = Get-Cluster  -Name "Cluster"


$vSphereWithTanzuParams = @{
    TanzuvCenterServer = "vcsa-01.haas-509.pez.vmware.com";
    TanzuvCenterServerUsername = "administrator@vsphere.local";
    TanzuvCenterServerPassword = "pass";
    ClusterName = "Cluster";
    TanzuContentLibrary = "Kubernetes";
    ControlPlaneSize = "TINY";
    MgmtNetwork = "Management";
    MgmtNetworkStartIP = "10.212.160.45";
    MgmtNetworkSubnet = "255.255.255.0";
    MgmtNetworkGateway = "10.212.160.1";
    MgmtNetworkDNS = @("10.192.2.10");
    MgmtNetworkDNSDomain = "haas-509.pez.vmware.com";
    MgmtNetworkNTP = @("ntp1.svc.pivotal.io");
    WorkloadNetwork = "Workload";
    WorkloadNetworkStartIP = "10.212.161.51";
    WorkloadNetworkIPCount = 28;
    WorkloadNetworkSubnet = "255.255.255.0";
    WorkloadNetworkGateway = "10.212.161.1";
    WorkloadNetworkDNS = @("10.192.2.10");
    WorkloadNetworkServiceCIDR = "10.96.0.0/24";
    StoragePolicyName = "tanzu";
    NSXALBIPAddress = "avi.haas-509.pez.vmware.com";
    NSXALBPort = "443";
    NSXALBCertName = "avi"
    NSXALBUsername = "admin";
    NSXALBPassword = "pass";
}
New-WorkloadManagement3 @vSphereWithTanzuParams 