##
<#
.SYNOPSIS
    Example script that deploys vSphere with Tanzu Workload Management on clusters using VDS networking
.DESCRIPTION
    Introduced in vSphere 7 Update 1, vSphere with Tanzu uses virtual distributed switches
    and an HAProxy VM to provide network isolation and load balancing for Kubernetes workloads.
    This script deploys the Workload Management component.
.EXAMPLE

.INPUTS
    vCenter FQDN/IP
.OUTPUTS
    Output (if any)
.NOTES


#>
#Connect to vCenter. Edit values as appropriate.
#Param(
#    [Parameter(Position=1)]
#    [string]$vc = "vcsa-02.haas-509.pez.vmware.com",
#
#    [Parameter(Position=2)]
#    [string]$vc_user = "administrator@vsphere.local",
#
#    [Parameter(Position=3)]
#    [string]$vc_password = "VMware1!"
#    )
#
#
## if ($global:DefaultVIServers) {
##     Disconnect-VIServer -Server $global:DefaultVIServers -Force -confirm:$false
##     Connect-VIServer -User $vc_user -Password $vc_password -Server $vc
##     } else {
#        Connect-VIServer -User $vc_user -Password $vc_password -Server $vc
##    }

$Cluster = Get-Cluster  -Name "Workload-Cluster"
$datacenter = Get-Datacenter "Tanzu-Datacenter"
$datastore = Get-Datastore -Name  "vsanDatastore"
$vmhosts = Get-VMHost
$tkgcl = "TKG-Content-Library"
$ntpservers = @("time.vmware.com")
$ManagementVirtualNetwork = get-virtualnetwork "DVPG-Supervisor-Management-Network"
#
$HAProxyVMname = "tanzu-haproxy-1"
#$AdvancedSettingName = "guestinfo.dataplaneapi.cacert"
#$Base64cert = get-vm $HAProxyVMname |Get-AdvancedSetting -Name $AdvancedSettingName
#while ([string]::IsNullOrEmpty($Base64cert.Value)) {
#            Write-Host "Waiting for CA Cert Generation... This may take a under 5-10 minutes as the VM needs to boot and generate the CA Cert (if you haven't provided one already)."
#        $Base64cert = get-vm $HAProxyVMname |Get-AdvancedSetting -Name $AdvancedSettingName
#        Start-sleep -seconds 2
#    }
#    Write-Host "CA Cert Found... Converting from BASE64"
#    $cert = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($Base64cert.Value))
    $cert = @"
-----BEGIN CERTIFICATE-----
MIIEJjCCAw6gAwIBAgIJAKBzN7aRF+WIMA0GCSqGSIb3DQEBCwUAMG8xCzAJBgNV
BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRIwEAYDVQQHDAlQYWxvIEFsdG8x
DzANBgNVBAoMBlZNd2FyZTENMAsGA1UECwwEQ0FQVjEXMBUGA1UEAwwOMTAuMjEy
LjE2MC4xMTYwHhcNMjExMjI5MTEyNzI3WhcNMzExMjI3MTEyNzI3WjCBiDELMAkG
A1UEBhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExEjAQBgNVBAcMCVBhbG8gQWx0
bzEPMA0GA1UECgwGVk13YXJlMQ0wCwYDVQQLDARDQVBWMTAwLgYDVQQDDCd0YW56
dS1oYXByb3h5LTEuaGFhcy01MDkucGV6LnZtd2FyZS5jb20wggEiMA0GCSqGSIb3
DQEBAQUAA4IBDwAwggEKAoIBAQDWlEZktCYw9F9ZU6a95b9uspPGKeylE7ht+CCo
yxXkhlTZaorYKNJrdM3oGf4fbZ440thcMN8Crs6g4lpHU0i/BtOkXPcVlp+oeR8f
5KK2N8WVyU2y/5iPEJXexuPDYnYCuOFojNGrVu4xIubljEmDAAvkV0fort3g5945
WJ7/q5jEBWkmgxRqLIbWuQLE+Ov0IWi4HgeSg1eFAnIdlEGToyhZ9ktjtfx1NQYL
8uQjT0+s0xv9gMQrqrcXbB+seRakTACO4nOgcheLcrrTSMDT3apflXsRkHB92/bF
S5vovnUxTBjKzcupULDzUcdV/iBRZGrz2GILxFWaxQNEviCbAgMBAAGjgaowgacw
CQYDVR0TBAIwADALBgNVHQ8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsG
AQUFBwMBMB0GA1UdDgQWBBS3i09tlwty3hnEHuwHicmIQ29CtTBPBgNVHREESDBG
gid0YW56dS1oYXByb3h5LTEuaGFhcy01MDkucGV6LnZtd2FyZS5jb22CCWxvY2Fs
aG9zdIcEfwAAAYcECtSgdIcECtShgDANBgkqhkiG9w0BAQsFAAOCAQEADUq0N0Nk
RwIXEfmOqoQsbPbvDoZHvHRwqDdQkPdNA/qed2Nhpnb1nFaVoxQv92SXZjTiodr/
EErmF5xWSupYJcQ+spzNck8fWVarp1S8M8JndA4p4rNx9SI9lBiiRjx0nvuK+ANq
0bZ1t+XbpJ/bjjvAc8tm2sZ7bt5OKC7nQHgPxz7AnDfRl/1AYXCCP9mu+ISZV2+2
lWBcNDFdBvIGO/6gqWtCDlhaAw/IfzYFrxkh+SHqxIEmqJ1ELtOYvSX2DylT01KA
Cyn+FN2uNFtYdXN0KzP7te4FSJLM8O/BUKWFXHGpkTp7C2NaNfQYvqgsqFFxvWi8
JyC48HQc1ylbag==
-----END CERTIFICATE-----
"@
#
Write-Host "Enabling Workload Management"
Get-Cluster $Cluster | Enable-WMCluster `
       -SizeHint Tiny `
       -ManagementVirtualNetwork $ManagementVirtualNetwork `
       -ManagementNetworkMode StaticRange `
       -ManagementNetworkGateway "10.212.160.1" `
       -ManagementNetworkSubnetMask "255.255.255.0" `
       -ManagementNetworkStartIPAddress "10.212.160.120" `
       -ManagementNetworkAddressRangeSize 5 `
       -MasterDnsServerIPAddress @("10.192.2.10") `
       -MasterNtpServer @("time.vmware.com") `
       -ServiceCIDR "10.96.0.0/24" `
       -EphemeralStoragePolicy "tanzu-gold-storage-policy" `
       -ImageStoragePolicy "tanzu-gold-storage-policy" `
       -MasterStoragePolicy "tanzu-gold-storage-policy" `
       -MasterDnsSearchDomain "haas-509.pez.vmware.com" `
       -ContentLibrary $tkgcl `
       -HAProxyName $HAProxyVMname `
       -HAProxyAddressRanges "10.212.161.128-10.212.161.160" `
       -HAProxyUsername "admin" `
       -HAProxyPassword "VMware1!" `
       -HAProxyDataPlaneAddresses "110.212.160.116:5556" `
       -HAProxyServerCertificateChain $cert `
       -WorkerDnsServer "10.192.2.10" `
       -PrimaryWorkloadNetworkSpecification ( New-WMNamespaceNetworkSpec `
          -Name "network-1" `
          -Gateway "10.212.161.1" `
          -Subnet "255.255.255.0" `
          -AddressRanges "10.212.161.180-10.212.161.200" `
          -DistributedPortGroup "DVPG-Workload-Network" `
       )
