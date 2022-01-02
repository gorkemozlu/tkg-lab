
$NSXAdvLBOVA = "/home/ubuntu/tool/controller-21.1.3-9051.ova"

Import-Module VMware.PowerCLI

# VCSA Deployment Configuration

$VCSAHostname = "vcsa-01.haas-509.pez.vmware.com" #Change to IP if you don't have valid DNS
$VCSAUsername = "administrator@vsphere.local"
$VCSASSOPassword = "pass"
$VCSARootPassword = "pass"

$viConnection = Connect-VIServer -User $VCSAUsername -Password $VCSASSOPassword -Server $VCSAHostname

# NSX Advanced LB Configuration
$NSXAdvLBDisplayName = "tanzu-nsx-alb"
$NSXAdvLByManagementIPAddress = "10.212.160.6"
$NSXAdvLBHostname = "avi.haas-509.pez.vmware.com"
$NSXAdvLBAdminPassword = "pass"
$NSXAdvLBvCPU = "8" #GB
$NSXAdvLBvMEM = "24" #GB
$NSXAdvLBPassphrase = "pass"
$NSXAdvLBIPAMName = "Tanzu-Default-IPAM"

# Service Engine Management Network Configuration
$NSXAdvLBManagementNetwork = "10.212.160.0"
$NSXAdvLBManagementNetworkPrefix = "24"
$NSXAdvLBManagementNetworkStartRange = "10.212.160.45"
$NSXAdvLBManagementNetworkEndRange = "10.212.160.55"

# VIP/Workload Network Configuration
$NSXAdvLBWorkloadNetwork = "10.212.161.0"
$NSXAdvLBWorkloadNetworkPrefix = "24"
$NSXAdvLBWorkloadNetworkStartRange = "10.212.161.51"
$NSXAdvLBWorkloadNetworkEndRange = "10.212.161.78"

# Self-Sign TLS Certificate
$NSXAdvLBSSLCertName = "avi"
$NSXAdvLBSSLCertExpiry = "365" # Days
$NSXAdvLBSSLCertEmail = "admini@primp-industries.local"
$NSXAdvLBSSLCertOrganizationUnit = "R&D"
$NSXAdvLBSSLCertOrganization = "primp-industries"
$NSXAdvLBSSLCertLocation = "Palo Alto"
$NSXAdvLBSSLCertState = "CA"
$NSXAdvLBSSLCertCountry = "US"

# General Deployment Configuration for Nested ESXi, VCSA & NSX Adv LB VM

$VMNetwork = "Management"

$VMGateway = "10.212.160.1"
$VMDNS = "10.192.2.10"

$VMDomain = "haas-509.pez.vmware.com"


# Applicable to Nested ESXi only


# Name of new vSphere Datacenter/Cluster when VCSA is deployed
$NewVCDatacenterName = "Datacenter"
$cluster = Get-Cluster  -Name "Cluster"
$vmhosts = Get-VMHost
$vmhost = $vmhosts[0]
$datastore = "LUN01"
$NewVCMgmtPortgroupName = "Management"
$NewVCWorkloadPortgroupName = "Workload"



####################################################1111111111>>>>>>>>>>>>
Function My-Logger {
    param(
    [Parameter(Mandatory=$true)][String]$message,
    [Parameter(Mandatory=$false)][String]$color="green"
    )

    $timeStamp = Get-Date -Format "MM-dd-yyyy_hh:mm:ss"

    Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
    Write-Host -ForegroundColor $color " $message"
    $logMessage = "[$timeStamp] $message"
    $logMessage | Out-File -Append -LiteralPath $verboseLogFile
}

$verboseLogFile = "tanzu-nsx-adv-lb-lab-deployment.log"
$random_string = -join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})
$VAppName = "Nested-Tanzu-NSX-Adv-LB-Lab-$random_string"

$preCheck = 1
$confirmDeployment = 1
$deployNSXAdvLB = 1
$deployNestedESXiVMs = 1
$deployVCSA = 1
$setupNewVC = 1
$addESXiHostsToVC = 1
$configureVSANDiskGroup = 1
$configureVDS = 1
$clearVSANHealthCheckAlarm = 1
$setupTanzuStoragePolicy = 1
$setupTanzu = 1
$setupNSXAdvLB = 0
$moveVMsIntovApp = 1

$vcsaSize2MemoryStorageMap = @{
"tiny"=@{"cpu"="2";"mem"="12";"disk"="415"};
"small"=@{"cpu"="4";"mem"="19";"disk"="480"};
"medium"=@{"cpu"="8";"mem"="28";"disk"="700"};
"large"=@{"cpu"="16";"mem"="37";"disk"="1065"};
"xlarge"=@{"cpu"="24";"mem"="56";"disk"="1805"}
}

$esxiTotalCPU = 0
$vcsaTotalCPU = 0
$esxiTotalMemory = 0
$vcsaTotalMemory = 0
$esxiTotalStorage = 0
$vcsaTotalStorage = 0
$nsxalbTotalStorage = 128

$StartTime = Get-Date

Function Get-SSLThumbprint {
    param(
    [Parameter(
        Position=0,
        Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ]
    [Alias('FullName')]
    [String]$URL
    )

    $Code = @'
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
namespace CertificateCapture
{
    public class Utility
    {
        public static Func<HttpRequestMessage,X509Certificate2,X509Chain,SslPolicyErrors,Boolean> ValidationCallback =
            (message, cert, chain, errors) => {
                var newCert = new X509Certificate2(cert);
                var newChain = new X509Chain();
                newChain.Build(newCert);
                CapturedCertificates.Add(new CapturedCertificate(){
                    Certificate =  newCert,
                    CertificateChain = newChain,
                    PolicyErrors = errors,
                    URI = message.RequestUri
                });
                return true;
            };
        public static List<CapturedCertificate> CapturedCertificates = new List<CapturedCertificate>();
    }
    public class CapturedCertificate
    {
        public X509Certificate2 Certificate { get; set; }
        public X509Chain CertificateChain { get; set; }
        public SslPolicyErrors PolicyErrors { get; set; }
        public Uri URI { get; set; }
    }
}
'@
    if ($PSEdition -ne 'Core'){
        Add-Type -AssemblyName System.Net.Http
        if (-not ("CertificateCapture" -as [type])) {
            Add-Type $Code -ReferencedAssemblies System.Net.Http
        }
    } else {
        if (-not ("CertificateCapture" -as [type])) {
            Add-Type $Code
        }
    }

    $Certs = [CertificateCapture.Utility]::CapturedCertificates

    $Handler = [System.Net.Http.HttpClientHandler]::new()
    $Handler.ServerCertificateCustomValidationCallback = [CertificateCapture.Utility]::ValidationCallback
    $Client = [System.Net.Http.HttpClient]::new($Handler)
    $Result = $Client.GetAsync($Url).Result

    $sha1 = [Security.Cryptography.SHA1]::Create()
    $certBytes = $Certs[-1].Certificate.GetRawCertData()
    $hash = $sha1.ComputeHash($certBytes)
    $thumbprint = [BitConverter]::ToString($hash).Replace('-',':')
    return $thumbprint.toLower()
}

if($deployNSXAdvLB -eq 1) {
    $ovfconfig = Get-OvfConfiguration $NSXAdvLBOVA

    $ovfconfig.NetworkMapping.Management.value = $VMNetwork
    $ovfconfig.avi.CONTROLLER.mgmt_ip.value = $NSXAdvLByManagementIPAddress
    $ovfconfig.avi.CONTROLLER.default_gw.value = $VMGateway

    My-Logger "Deploying NSX Advanced LB VM $NSXAdvLBDisplayName ..."
    $vm = Import-VApp -Source $NSXAdvLBOVA -OvfConfiguration $ovfconfig -Name $NSXAdvLBDisplayName -Location $cluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

    My-Logger "Updating vCPU Count to $NSXAdvLBvCPU & vMEM to $NSXAdvLBvMEM GB ..."
    Set-VM -Server $viConnection -VM $vm -NumCpu $NSXAdvLBvCPU -MemoryGB $NSXAdvLBvMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

    My-Logger "Powering On $NSXAdvLBDisplayName ..."
    $vm | Start-Vm -RunAsync | Out-Null
}

if($setupNSXAdvLB -eq 1) {
    # NSX ALB can take up to several minutes to initialize upon initial power on
    while(1) {
        try {
            $response = Invoke-WebRequest -Uri http://${NSXAdvLByManagementIPAddress} -SkipCertificateCheck
            if($response.StatusCode -eq 200) {
                My-Logger "$NSXAdvLBDisplayName is now ready for configuration ..."
                break
            }
        } catch {
            My-Logger "$NSXAdvLBDisplayName is not ready, sleeping for 2 minutes ..."
            Start-Sleep -Seconds 120
        }
    }

    # Assumes Basic Auth has been enabled per automation below
    $pair = "admin:$VCSASSOPassword"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)

    $newPassbasicAuthHeaders = @{
        "Authorization"="basic $base64";
        "Content-Type"="application/json";
        "Accept"="application/json";
        "x-avi-version"="20.1.4";
    }

    $enableBasicAuth=1
    $updateAdminPassword=1
    $updateBackupPassphrase=1
    $updateDnsAndSMTPSettings=1
    $updateWelcomeWorkflow=1
    $createSSLCertificate=1
    $updateSSlCertificate=1
    $registervCenter=1
    $updateVCMgmtNetwork=1
    $updateVCWorkloadNetwork=1
    $createDefaultIPAM=1
    $updateDefaultIPAM=1

    if($enableBasicAuth -eq 1) {
        $headers = @{
            "Content-Type"="application/json"
            "Accept"="application/json"
        }

        $payload = @{
            username="admin";
            password="58NFaGDJm(PJH0G";
        }

        $defaultPasswordBody = $payload | ConvertTo-Json

        $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/login -Body $defaultPasswordBody -Method POST -Headers $headers -SessionVariable WebSession -SkipCertificateCheck
        $csrfToken = $WebSession.Cookies.GetCookies("https://${NSXAdvLByManagementIPAddress}/login")["csrftoken"].value

        $headers = @{
            "Content-Type"="application/json"
            "Accept"="application/json"
            "x-avi-version"="20.1.4"
            "x-csrftoken"=$csrfToken
            "referer"="https://${NSXAdvLByManagementIPAddress}/login"
        }

        $json = (Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -Method GET -Headers $headers -WebSession $WebSession -SkipCertificateCheck).Content | ConvertFrom-Json
        $json.portal_configuration.allow_basic_authentication = $true
        $systemConfigBody = $json | ConvertTo-Json -Depth 10

        try {
            My-Logger "Enabling bacic auth ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -Body $systemConfigBody -Method PUT -Headers $headers -WebSession $WebSession -SkipCertificateCheck
        } catch {
            My-Logger "Failed to update basic auth" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully enabled basic auth for $NSXAdvLBDisplayName ..."
        } else {
            My-Logger "Something went wrong enabling basic auth" "yellow"
            $response
            break
        }
    }

    if($updateAdminPassword -eq 1) {
        $pair = "admin:58NFaGDJm(PJH0G"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)

        $basicAuthHeaders = @{
            "Authorization"="basic $base64"
            "Content-Type"="application/json"
            "Accept"="application/json"
        }

        $payload = @{
            old_password = "58NFaGDJm(PJH0G";
            password = $NSXAdvLBAdminPassword;
            username = "admin"
        }

        $newPasswordBody = $payload | ConvertTo-Json

        try {
            My-Logger "Changing default admin password"
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/useraccount -Body $newPasswordBody -Method PUT -Headers $basicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Failed to change admin password" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully changed default admin password ..."
        } else {
            My-Logger "Something went wrong changing default admin password" "yellow"
            $response
            break
        }
    }

    if($updateBackupPassphrase -eq 1) {
        $backupJsonResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/backupconfiguration -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results[0]

        $passPhraseJson = @{
            "add" = @{
                "backup_passphrase" = $nsxAdvLBPassphrase;
            }
        }
        $newBackupJsonBody = ($passPhraseJson | ConvertTo-json)

        try {
            My-Logger "Configuring backup passphrase ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/backupconfiguration/$($backupJsonResult.uuid) -body $newBackupJsonBody -Method PATCH -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Failed to update backup passphrase" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully updated backup passphrase ..."
        } else {
            My-Logger "Something went wrong updating backup passphrase" "yellow"
            $response
            break
        }
    }

    if($updateDnsAndSMTPSettings -eq 1) {
        $dnsResults = (Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json

        $dnsResults.dns_configuration.search_domain = "$VMDomain"
        $dnsResults.email_configuration.smtp_type = "SMTP_NONE"

        $dnsConfig = @{
            "addr" = "$VMDNS";
            "type" = "V4";
        }

        $dnsResults.dns_configuration | Add-Member -MemberType NoteProperty -Name server_list -Value @($dnsConfig)
        $newDnsJsonBody = ($dnsResults | ConvertTo-json -Depth 4)

        try {
            My-Logger "Configuring DNS and SMTP settings"
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -body $newDnsJsonBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Failed to update DNS and SMTP settings" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully updated DNS and SMTP settings ..."
        } else {
            My-Logger "Something went wrong with updating DNS and SMTP settings" "yellow"
            $response
            break
        }
    }

    if($updateWelcomeWorkflow -eq 1) {
        $welcomeWorkflowJson = @{
            "replace" = @{
                "welcome_workflow_complete" = "true";
            }
        }

        $welcomeWorkflowBody = ($welcomeWorkflowJson | ConvertTo-json)

        try {
            My-Logger "Disabling initial welcome message ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -body $welcomeWorkflowBody -Method PATCH -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Failed to disable welcome workflow message" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully disabled welcome workflow message ..."
        } else {
            My-Logger "Something went wrong disabling welcome workflow message" "yellow"
            $response
            break
        }
    }

    if($createSSLCertificate -eq 1) {

        $selfSignCertPayload = @{
            "certificate" = @{
                "expiry_status" = "SSL_CERTIFICATE_GOOD";
                "days_until_expire" = $NSXAdvLBSSLCertExpiry;
                "self_signed" = "true"
                "subject" = @{
                    "common_name" = $NSXAdvLBHostname;
                    "email_address" = $NSXAdvLBSSLCertEmail;
                    "organization_unit" = $NSXAdvLBSSLCertOrganizationUnit;
                    "organization" = $NSXAdvLBSSLCertOrganization;
                    "locality" = $NSXAdvLBSSLCertLocation;
                    "state" = $NSXAdvLBSSLCertState;
                    "country" = $NSXAdvLBSSLCertCountry;
                };
                "subject_alt_names" = @($NSXAdvLBHostname);
            };
            "key_params" = @{
                "algorithm" = "SSL_KEY_ALGORITHM_RSA";
                "rsa_params" = @{
                    "key_size" = "SSL_KEY_2048_BITS";
                    "exponent" = "65537";
                };
            };
            "status" = "SSL_CERTIFICATE_FINISHED";
            "format" = "SSL_PEM";
            "certificate_base64" = "true";
            "key_base64" = "true";
            "type" = "SSL_CERTIFICATE_TYPE_SYSTEM";
            "name" = $NSXAdvLBSSLCertName;
        }

        $selfSignCertBody = ($selfSignCertPayload | ConvertTo-Json -Depth 8)

        try {
            My-Logger "Creating self-sign TLS certificate ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/sslkeyandcertificate -body $selfSignCertBody -Method POST -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Error in creating self-sign TLS certificate" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 201) {
            My-Logger "Successfully created self-sign TLS certificate ..."
        } else {
            My-Logger "Something went wrong creating self-sign TLS certificate" "yellow"
            $response
            break
        }
    }

    if($updateSSlCertificate -eq 1) {
        $certJsonResults = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/sslkeyandcertificate?include_name -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | where {$_.name -eq $NSXAdvLBSSLCertName}

        $systemConfigJsonResults = (Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json

        $systemConfigJsonResults.portal_configuration.sslkeyandcertificate_refs = @(${certJsonResults}.url)

        $updateSSLCertBody = $systemConfigJsonResults | ConvertTo-Json -Depth 4

        try {
            My-Logger "Updating NSX ALB to new self-sign TLS ceretificate ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/systemconfiguration -body $updateSSLCertBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Error in updating self-sign TLS certificate" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully updated to new self-sign TLS certificate ..."
        } else {
            My-Logger "Something went wrong updating to new self-sign TLS certificate" "yellow"
            $response
            break
        }
    }

    if($registervCenter -eq 1) {
        $cloudConfigResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results[0]

        $cloudConfigResult.vtype = "CLOUD_VCENTER"

        $vcConfig = @{
            "username" = "administrator@vsphere.local"
            "password" = "$VCSASSOPassword";
            "vcenter_url" = "$VCSAHostname";
            "privilege" = "WRITE_ACCESS";
            "datacenter" ="$NewVCDatacenterName";
            "management_ip_subnet" = @{
                "ip_addr" = @{
                    "addr" = "$NSXAdvLBManagementNetwork";
                    "type" = "V4";
                };
                "mask" = "$NSXAdvLBManagementNetworkPrefix";
            }
        }

        $cloudConfigResult | Add-Member -MemberType NoteProperty -Name vcenter_configuration -Value $vcConfig

        $newCloudConfigBody = ($cloudConfigResult | ConvertTo-Json -Depth 4)

        try {
            My-Logger "Register Tanzu vCenter Server $VCSAHostname to NSX ALB ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud/$($cloudConfigResult.uuid) -body $newCloudConfigBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Failed to register Tanzu vCenter Server" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully registered Tanzu vCenter Server ..."
        } else {
            My-Logger "Something went wrong registering Tanzu vCenter Server" "yellow"
            $response
            break
        }
    }

    if($updateVCMgmtNetwork -eq 1) {
        Start-Sleep -Seconds 20

        $cloudNetworkResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | where {$_.name -eq $NewVCMgmtPortgroupName}

        $mgmtNetworkConfig = @{
            "prefix" = @{
                "ip_addr" = @{
                    "addr" = "$NSXAdvLBManagementNetwork";
                    "type" = "V4";
                };
                "mask" = "$NSXAdvLBManagementNetworkPrefix";
            };
            "static_ip_ranges" = @(
                @{
                    "range" = @{
                        "begin" = @{
                            "addr" = $NSXAdvLBManagementNetworkStartRange;
                            "type" = "V4";
                        };
                        "end" = @{
                            "addr" = $NSXAdvLBManagementNetworkEndRange;
                            "type" = "V4";
                        }
                    };
                    "type" = "STATIC_IPS_FOR_VIP_AND_SE";
                }
            )
        }

        $cloudNetworkResult | Add-Member -MemberType NoteProperty -Name configured_subnets -Value @($mgmtNetworkConfig)

        $newCloudMgmtNetworkBody = ($cloudNetworkResult | ConvertTo-Json -Depth 10)

        # Create Subnet mapping
        try {
            My-Logger "Creating subnet mapping for Service Engine Network ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network/$($cloudNetworkResult.uuid) -body $newCloudMgmtNetworkBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Failed to create subnet mapping for $NewVCMgmtPortgroupName" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully created subnet mapping for $NewVCMgmtPortgroupName ..."
        } else {
            My-Logger "Something went wrong creating subnet mapping for $NewVCMgmtPortgroupName" "yellow"
            $response
            break
        }

        # Add default Gateway
        $vrfContextResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/vrfcontext -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | where {$_.name -eq "management"}

        $staticRouteConfig = @{
            "next_hop" = @{
                "addr" = $VMGateway;
                "type" = "V4";
            };
            "route_id" = "1";
            "prefix" = @{
                "ip_addr" = @{
                    "addr" = "0.0.0.0";
                    "type" = "V4";
                };
                "mask" = "0"
            }
        }

        $vrfContextResult |  Add-Member -MemberType NoteProperty -Name static_routes -Value @($staticRouteConfig)

        $newvrfContextkBody = ($vrfContextResult | ConvertTo-Json -Depth 10)

        try {
            My-Logger "Updating VRF Context for default gateway ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/vrfcontext/$(${vrfContextResult}.uuid) -body $newvrfContextkBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Failed to update VRF context" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully updated VRF context ..."
        } else {
            My-Logger "Something went wrong updating VRF context" "yellow"
            $response
            break
        }

        # Associtae Tanzu Management Network to vCenter
        $cloudNetworkResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | where {$_.name -eq $NewVCMgmtPortgroupName}

        $cloudConfigResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results[0]


        $cloudConfigResult.vcenter_configuration | Add-Member -MemberType NoteProperty -Name management_network -Value $(${cloudNetworkResult}.vimgrnw_ref)
        $newCloudConfigBody = ($cloudConfigResult | ConvertTo-Json -Depth 4)

        try {
            My-Logger "Associating Service Engine network to Tanzu vCenter Server ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud/$(${cloudConfigResult}.uuid) -body $newCloudConfigBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Failed to associate service engine network to Tanzu vCenter Server" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully associated service engine network to Tanzu vCenter Server ..."
        } else {
            My-Logger "Something went wrong associating service engine network to Tanzu vCenter Server" "yellow"
            $response
            break
        }
    }

    if($updateVCWorkloadNetwork -eq 1) {
        $cloudNetworkResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | where {$_.name -eq $NewVCWorkloadPortgroupName}

        $workloadNetworkConfig = @{
            "prefix" = @{
                "ip_addr" = @{
                    "addr" = "$NSXAdvLBWorkloadNetwork";
                    "type" = "V4";
                };
                "mask" = "$NSXAdvLBWorkloadNetworkPrefix";
            };
            "static_ip_ranges" = @(
                @{
                    "range" = @{
                        "begin" = @{
                            "addr" = $NSXAdvLBWorkloadNetworkStartRange;
                            "type" = "V4";
                        };
                        "end" = @{
                            "addr" = $NSXAdvLBWorkloadNetworkEndRange;
                            "type" = "V4";
                        }
                    };
                    "type" = "STATIC_IPS_FOR_VIP_AND_SE";
                }
            )
        }

        $cloudNetworkResult | Add-Member -MemberType NoteProperty -Name configured_subnets -Value @($workloadNetworkConfig)

        $newCloudWorkloadNetworkBody = ($cloudNetworkResult | ConvertTo-Json -Depth 10)

        # Create Subnet mapping
        try {
            My-Logger "Creating subnet mapping for Workload Network ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network/$($cloudNetworkResult.uuid) -body $newCloudWorkloadNetworkBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Failed to create subnet mapping for $NewVCWorkloadPortgroupName" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully created subnet mapping for $NewVCWorkloadPortgroupName ..."
        } else {
            My-Logger "Something went wrong creating subnet mapping for $NewVCWorkloadPortgroupName" "yellow"
            $response
            break
        }
    }

    if($createDefaultIPAM -eq 1) {
        $cloudNetworkResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/network -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | where {$_.name -eq $NewVCWorkloadPortgroupName}

        $ipamConfig = @{
            "name" = $NSXAdvLBIPAMName;
            "tenant_ref" = "https://${NSXAdvLByManagementIPAddress}/tenant/admin";
            "type" = "IPAMDNS_TYPE_INTERNAL";
            "internal_profile" = @{
                "ttl" = "30";
                "usable_networks" = @(
                    @{
                        "nw_ref" = "$(${cloudNetworkResult}.url)"
                    }
                );
            };
            "allocate_ip_in_vrf" = "true"
        }

        $ipamBody = $ipamConfig | ConvertTo-Json -Depth 4

        try {
            My-Logger "Creating new IPAM Default Profile ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/ipamdnsproviderprofile -body $ipamBody -Method POST -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Failed to create IPAM default profile" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 201) {
            My-Logger "Successfully created IPAM default profile ..."
        } else {
            My-Logger "Something went wrong creating IPAM default profile" "yellow"
            $response
            break
        }
    }

    if($updateDefaultIPAM -eq 1) {
        $ipamResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/ipamdnsproviderprofile -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results | where {$_.name -eq $NSXAdvLBIPAMName}

        $cloudConfigResult = ((Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud -Method GET -Headers $newPassbasicAuthHeaders -SkipCertificateCheck).Content | ConvertFrom-Json).results[0]

        $cloudConfigResult | Add-Member -MemberType NoteProperty -Name ipam_provider_ref -Value $ipamResult.url

        $newClouddConfigBody = ($cloudConfigResult | ConvertTo-Json -Depth 10)

        try {
            My-Logger "Updating Default Cloud to new IPAM Profile ..."
            $response = Invoke-WebRequest -Uri https://${NSXAdvLByManagementIPAddress}/api/cloud/$($cloudConfigResult.uuid) -body $newClouddConfigBody -Method PUT -Headers $newPassbasicAuthHeaders -SkipCertificateCheck
        } catch {
            My-Logger "Failed to update default IPAM profile" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }

        if($response.Statuscode -eq 200) {
            My-Logger "Successfully updated default IPAM profile ..."
        } else {
            My-Logger "Something went wrong updating default IPAM profile" "yellow"
            $response
            break
        }
    }
}
