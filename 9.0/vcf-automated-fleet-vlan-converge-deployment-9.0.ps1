# Author: William Lam
# Website: https://williamlam.com

# Contributor: Abbed Sedkaoui
# Website: https://strivevirtually.net

param (
    [string]$EnvConfigFile
)

# Validate that the file exists
if ($EnvConfigFile -and (Test-Path $EnvConfigFile)) {
    . $EnvConfigFile  # Dot-sourcing the config file
} else {
    Write-Host -ForegroundColor Red "`nNo valid deployment configuration file was provided or file was not found.`n"
    exit
}

#### DO NOT EDIT BEYOND HERE ####

# VCF Instance Deployment JSON
$random_string = -join ((48..57) + (97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})

#$random_string = "bkjwo4hi" # uncomment to reuse the script on the same vApp with its generated Deployment Id and comment the original $random_string

$VAppName = "Nested-${VCFInstallerProductSKU}-9-Lab-${VAppLabel}-${random_string}"
$VCFManagementDomainJSONFile = "$(${VCFInstallerProductSKU}.toLower())-mgmt-${random_string}.json"
$verboseLogFile = "vcf-9-lab-deployment-${random_string}.log"
$bootStrapNode = $($NestedESXiHostnameToIPsForManagementDomain.Keys|Sort-Object) | Select-Object -Index 0
$WarningPreference = 'SilentlyContinue'

$preCheck = 1
$confirmDeployment = 1
$deployVCFInstaller = 1
$updateVCFInstallerConfig = 1
$deployNestedESXiVMsForMgmt = 1
$restartNestedMgmtVM = 1

$deployNestedESXiVMsForWLD = 0
$restartNestedWldVM = 0

$setVLanId = 1
$setupEntropy = 1
$bootStrapFirstNestedESXiVM = 1

$deployVCSA = 1
$setupNewVC = 1
$addESXiHostsToVC = 1
$configureVSANDiskGroup = 1
$setupVsanStoragePolicy = 1
$configureVDS = 1
$migrateVMstoVDS = 1
$migrateVmkernelToVDS = 1
$removeVSS = 1
$finalCleanUp = 1

$deployNSXManager = 1
$postDeployNSXConfig = 1


$moveVMsIntovApp = 1
$configureVCFInstallerConfig = 1
$generateMgmtJson = 1
$startVCFBringup = 1
$updateSddcManagerConfig = 1

$uploadVCFNotifyScript = 0

$srcNotificationScript = "vcf-bringup-notification.sh"
$dstNotificationScript = "/root/vcf-bringup-notification.sh"

$StartTime = Get-Date

if( $VCSAuseExistingDeploymentvCenter -eq 1) {
    
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
            try { Add-Type $Code -ReferencedAssemblies System.Net.Http } catch {}
        }
    } else {
        if (-not ("CertificateCapture" -as [type])) {
            try { Add-Type $Code -ErrorAction SilentlyContinue } catch {}
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
    
Function Get-SSLThumbprint256 {
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
            try { Add-Type $Code -ReferencedAssemblies System.Net.Http } catch {}
        }
    } else {
        if (-not ("CertificateCapture" -as [type])) {
            try { Add-Type $Code -ErrorAction SilentlyContinue } catch {}
        }
    }

    $Certs = [CertificateCapture.Utility]::CapturedCertificates

    $Handler = [System.Net.Http.HttpClientHandler]::new()
    $Handler.ServerCertificateCustomValidationCallback = [CertificateCapture.Utility]::ValidationCallback
    $Client = [System.Net.Http.HttpClient]::new($Handler)
    $Result = $Client.GetAsync($Url).Result

    $sha256 = [Security.Cryptography.SHA256]::Create()
    $certBytes = $Certs[-1].Certificate.GetRawCertData()
    $hash = $sha256.ComputeHash($certBytes)
    $thumbprint = [BitConverter]::ToString($hash).Replace('-',':')
    return $thumbprint
}
}

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

Function Get-VCFInstallerToken {
    $payload = @{
        "username" = $VCFInstallerAdminUsername
        "password" = $VCFInstallerAdminPassword
    }

    $body = $payload | ConvertTo-Json

    try {
        $requests = Invoke-WebRequest -Uri "https://${VCFInstallerFQDN}/v1/tokens" -Method POST -SkipCertificateCheck -TimeoutSec 30 -Headers @{"Content-Type"="application/json";"Accept"="application/json"} -Body $body
        if($requests.StatusCode -eq 200) {
            $accessToken = ($requests.Content | ConvertFrom-Json).accessToken
        }
    } catch {
        My-Logger "Unable to retrieve VCF Installer Token ..."
        exit
    }

    $headers = @{
        "Content-Type"="application/json"
        "Accept"="application/json"
        "Authorization"="Bearer ${accessToken}"
    }

    return $headers
}

Function Download-VCFBundle {
    param(
        [Parameter(Mandatory=$true)][String]$BundleId
    )

    $headers = Get-VCFInstallerToken

    try {
        $payload = @{
            "bundleDownloadSpec" = @{
                "downloadNow" = $true
            }
        }

        $uri = "https://${VCFInstallerFQDN}/v1/bundles/$bundleId"
        $method = "PATCH"
        $body = $payload | ConvertTo-Json

        if($Debug) {
            My-Logger "DEBUG: Method: $method"
            My-Logger "DEBUG: Uri: $uri"
            My-Logger "DEBUG: Body: $body"
        }

        $requests = Invoke-WebRequest -Uri $uri -Method $method -SkipCertificateCheck -TimeoutSec 5 -Headers $headers -Body $body
    } catch {
        $error = ($_ | ConvertFrom-Json)
        if($error.errorCode -eq "BUNDLE_DOWNLOAD_ALREADY_DOWNLOADED") {
            continue
        } else {
            $_.Exception

            My-Logger "Failed to start VCF download for bundle ${bundleId}" "red"
            Write-Error "`n($_.Exception.Message)`n"
            break
        }
    }
}

Function Delete-VCFBundle {
    param(
        [Parameter(Mandatory=$true)][String]$BundleId
    )

    $headers = Get-VCFInstallerToken

    try {
        $uri = "https://${VCFInstallerFQDN}/v1/bundles/$bundleId"
        $method = "DELETE"
        $body = $null

        if($Debug) {
            My-Logger "DEBUG: Method: $method"
            My-Logger "DEBUG: Uri: $uri"
            My-Logger "DEBUG: Body: $body"
        }

        $requests = Invoke-WebRequest -Uri $uri -Method $method -SkipCertificateCheck -TimeoutSec 5 -Headers $headers
    } catch {
        My-Logger "Failed to delete VCF bundle ${bundleId}" "red"
        Write-Error "`n($_.Exception.Message)`n"
        break
    }
}

Function Verify-VCFAPIEndpoint {
    param(
        [Parameter(Mandatory=$true)][String]$EndpointName,
        [Parameter(Mandatory=$true)][String]$EndpointIp
    )

    while(1) {
        try {
            $method = "GET"
            $uri = "https://${EndpointIp}/v1/system/appliance-info"
            $requests = Invoke-WebRequest -Uri $uri -Method $method -SkipCertificateCheck -TimeoutSec 5
            if($requests.StatusCode -eq 200) {
                My-Logger "`t${EndpointName} API is now ready!"
                break
            }
        } catch {
            My-Logger "${EndpointName} API is not ready yet, sleeping for 120 seconds ..."
            Start-Sleep 120
        }
    }
}

Function Connect-VCFDepot {
    param(
        [Parameter(Mandatory=$true)][String]$EndpointIp
    )

    $headers = Get-VCFInstallerToken

    try {
        if($VCFInstallerSoftwareDepot -eq "offline") {
            $payload = @{
                "offlineAccount" = [Ordered]@{
                    "username" = $VCFInstallerDepotUsername
                    "password" = $VCFInstallerDepotPassword
                }
                "depotConfiguration" = @{
                    "isOfflineDepot" = $true
                    "hostname" = $VCFInstallerDepotHost
                    "port" = $VCFInstallerDepotPort
                }
            }
        } else {
            $payload = @{
                "vmwareAccount" = [Ordered]@{
                    "downloadToken" = $VCFInstallerDepotToken
                }
            }
        }

        $uri = "https://${EndpointIp}/v1/system/settings/depot"
        $method = "PUT"
        $body = $payload | ConvertTo-Json

        if($Debug) {
            My-Logger "DEBUG: Method: $method"
            My-Logger "DEBUG: Uri: $uri"
            My-Logger "DEBUG: Body: $body"
        }
	$requests = Invoke-WebRequest -Uri $uri -Method $method -SkipCertificateCheck -TimeoutSec 60 -Headers $headers -Body $body -ErrorAction Stop
    } catch {
	My-Logger "Failed to connect to VCF Software Depot" "red"
	$requests
        Write-Error "`n($_.Exception.Message)`n"
        break
    }

    if($requests.Statuscode -eq 202) {
        My-Logger "Successfully connected to VCF Software Depot ..."
    } else {
        My-Logger "Something went wrong updating connecting to VCF Software Depot" "yellow"
        $requests
        break
    }
}

Function Sync-VCFDepot {
    param(
        [Parameter(Mandatory=$true)][String]$EndpointIp
    )

    $headers = Get-VCFInstallerToken

    try {
        $uri = "https://${EndpointIp}/v1/system/settings/depot/depot-sync-info"
        $method = "PATCH"
        $body = $null

        if($Debug) {
            My-Logger "DEBUG: Method: $method"
            My-Logger "DEBUG: Uri: $uri"
            My-Logger "DEBUG: Body: $body"
        }

        $requests = Invoke-WebRequest -Uri $uri -Method $method -SkipCertificateCheck -TimeoutSec 5 -Headers $headers
    } catch {
        My-Logger "Failed to sync VCF Software Depot" "red"
        Write-Error "`n($_.Exception.Message)`n"
        break
    }

    if($requests.Statuscode -eq 202) {
        My-Logger "Successfully started VCF Software Depot sync ..."
    } else {
        My-Logger "Something went wrong starting VCF Software Depot sync" "yellow"
        $requests
        break
    }

    while(1) {
        try {
            $uri = "https://${EndpointIp}/v1/system/settings/depot/depot-sync-info"
            $method = "GET"
            $body = $null

            if($Debug) {
                My-Logger "DEBUG: Method: $method"
                My-Logger "DEBUG: Uri: $uri"
                My-Logger "DEBUG: Body: $body"
            }

            $requests = Invoke-WebRequest -Uri $uri -Method $method -SkipCertificateCheck -TimeoutSec 5 -Headers $headers
            if($requests.StatusCode -eq 200) {
                if(($requests.Content | ConvertFrom-Json).syncStatus -ne "SYNCED") {
                    My-Logger "VCF Software Depot Sync not ready yet, sleeping for 30 seconds ..."
                    Start-Sleep 30
                } else {
                    My-Logger "Successfully synced VCF Software Depot ..."
                    break
                }
            }
        }
        catch {
            My-Logger "Failed to sync VCF Software Depot ..."
            $requests
            exit
        }
    }
}

Function Download-VCFRelease {
    param(
        [Parameter(Mandatory=$true)][String]$EndpointIp
    )

    $headers = Get-VCFInstallerToken

    try {
        $uri = "https://${EndpointIp}/v1/releases/${VCFInstallerProductSKU}/release-components?releaseVersion=${VCFInstallerProductVersion}&automatedInstall=true&imageType=INSTALL"
        $method = "GET"
        $body = $null

        if($Debug) {
            My-Logger "DEBUG: Method: $method"
            My-Logger "DEBUG: Uri: $uri"
            My-Logger "DEBUG: Body: $body"
        }

        $requests = Invoke-WebRequest -Uri $uri -Method GET -SkipCertificateCheck -TimeoutSec 30 -Headers $headers
    } catch {
        My-Logger "Failed to retrieve $VCFInstallerProductSKU release" "red"
        Write-Error "`n($_.Exception.Message)`n"
        break
    }

    if($requests.Statuscode -eq 200) {
        My-Logger "Successfully retrieved $VCFInstallerProductSKU release ..."
    } else {
        My-Logger "Something went wrong retreiving $VCFInstallerProductSKU release" "yellow"
        $requests
        break
    }

    # Retreive the components for a given SKU
    $bundle = @{}
    $components = (($requests.Content | ConvertFrom-Json).elements | Where-Object {$_.releaseVersion -eq $VCFInstallerProductVersion}).components
    foreach ($component in $components) {
        $bundle[$component.name]=$component.versions.artifacts.bundles.id
    }

    # Download Bundle
    $bundle.GetEnumerator() | ForEach-Object {
        # SDDDCm is NOT required for VVF SKU
        if($VCFInstallerProductSKU -ne "VVF" -or $_.key -ne "SDDC_MANAGER") {
            My-Logger "Starting download for $($_.key) component ..."
            Download-VCFBundle -BundleId $_.value
        }
    }

    while(1) {
        try {
            $uri = "https://${EndpointIp}/v1/bundles/download-status?releaseVersion=${VCFInstallerProductVersion}&imageType=INSTALL"
            $method = "GET"
            $body = $null

            if($Debug) {
                My-Logger "DEBUG: Method: $method"
                My-Logger "DEBUG: Uri: $uri"
                My-Logger "DEBUG: Body: $body"
            }

            $requests = Invoke-WebRequest -Uri $uri -Method $method -SkipCertificateCheck -TimeoutSec 30 -Headers $headers
            if($requests.StatusCode -eq 200) {
                $downloadStatus = ($requests.Content | ConvertFrom-Json).elements.downloadStatus

                if($downloadStatus -contains "INPROGRESS" -or $downloadStatus -contains "SCHEDULED" -or $downloadStatus -contains "VALIDATING" -or $downloadStatus -contains "FAILED") {
                    if($downloadStatus -contains "FAILED") {
                        $failedBundles = (($requests.Content | ConvertFrom-Json).elements | Where-Object {$_.downloadStatus -eq "FAILED"})

                        foreach ($failedBundle in $failedBundles) {
                            My-Logger "Re-attempting to download $(${failedBundle}.componentType) component"
                            Delete-VCFBundle -BundleId $(${failedBundle}.bundleId)
                            Download-VCFBundle -BundleId $(${failedBundle}.bundleId)
                        }
                    }
                    My-Logger "$VCFInstallerProductSKU bundle download has not completed or has not been validated yet, sleeping for 5min ..."
                    Start-Sleep 300
                } else {
                    My-Logger "Successfully downloaded $VCFInstallerProductSKU ${VCFInstallerProductVersion} bundle ..."
                    break
                }
            }
        }
        catch {
            My-Logger "Failed to wait for $VCFInstallerProductSKU bundle download ..."
            $requests
            exit
        }
    }
}

if($preCheck -eq 1) {
    if($PSVersionTable.PSEdition -ne "Core") {
        Write-Host -ForegroundColor Red "`tPowerShell Core was not detected, please install that before continuing ... `n"
        exit
    }

    if(!(Test-Path $NestedESXiApplianceOVA)) {
        Write-Host -ForegroundColor Red "`nUnable to find $NestedESXiApplianceOVA ...`n"
        exit
    }

    if(!(Test-Path $VCFInstallerOVA)) {
        Write-Host -ForegroundColor Red "`nUnable to find $VCFInstallerOVA ...`n"
        exit
    }

    if(!(Test-Path $NSXTManagerOVA) -and $deployNSXManager -eq 1) {
        Write-Host -ForegroundColor Red "`nUnable to find $NSXTManagerOVA ...`n"
        exit
    }

    if($VCFInstallerSoftwareDepot -eq "offline") {
        try {
            (new-object System.Net.Sockets.TcpClient).Connect(${VCFInstallerDepotHost},${VCFInstallerDepotPort})
        } catch {
            Write-Host -ForegroundColor Red "`nUnable to reach VCF offline depot ${VCFInstallerDepotHost}:${VCFInstallerDepotPort} ...`n"
            exit
        }
    }
}

if($confirmDeployment -eq 1) {
    Write-Host -ForegroundColor Magenta "`nPlease confirm the following configuration will be deployed:`n"

    Write-Host -ForegroundColor Yellow "---- VCF Automated 9 Lab Deployment Configuration ---- "
    Write-Host -NoNewline -ForegroundColor Green "Generated Deployment ID: "
    Write-Host -ForegroundColor White $random_string
    Write-Host -NoNewline -ForegroundColor Green "Configuration Variables File: "
    Write-Host -ForegroundColor White $EnvConfigFile
    Write-Host -NoNewline -ForegroundColor Green "Nested ESXi Image Path: "
    Write-Host -ForegroundColor White $NestedESXiApplianceOVA
    Write-Host -NoNewline -ForegroundColor Green "VCF Installer Image Path: "
    Write-Host -ForegroundColor White $VCFInstallerOVA
	if($VCSAuseExistingDeploymentvCenter -eq 1) {
		Write-Host -NoNewline -ForegroundColor Green "VCSA Installer Image Path: "
		Write-Host -ForegroundColor White $VCSAInstallerPath
        if($NSXuseExistingDeploymentNSX -eq 1){
		Write-Host -NoNewline -ForegroundColor Green "NSX Image Path: "
		Write-Host -ForegroundColor White $NSXTManagerOVA
        }
	}
    
    
    Write-Host -ForegroundColor Yellow "`n---- vCenter Server Deployment Target Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "vCenter Server Address: "
    Write-Host -ForegroundColor White $VIServer
    Write-Host -NoNewline -ForegroundColor Green "VM Storage MGMT: "
    Write-Host -ForegroundColor White $VMDatastoreMGMT
	if($deployNestedESXiVMsForWLD -eq 1) {
	    Write-Host -NoNewline -ForegroundColor Green "VM Storage WLD: "
		Write-Host -ForegroundColor White $VMDatastoreWLD	
	}
    Write-Host -NoNewline -ForegroundColor Green "VM Cluster: "
    Write-Host -ForegroundColor White $VMCluster
    Write-Host -NoNewline -ForegroundColor Green "VM vApp: "
    Write-Host -ForegroundColor White $VAppName

    Write-Host -ForegroundColor Yellow "`n---- VCF Installer Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "Software SKU: "
    Write-Host -ForegroundColor White $VCFInstallerProductSKU
    Write-Host -NoNewline -ForegroundColor Green "Software Version: "
    Write-Host -ForegroundColor White $VCFInstallerProductVersion
    Write-Host -NoNewline -ForegroundColor Green "Hostname: "
    Write-Host -ForegroundColor White $VCFInstallerVMName
    Write-Host -NoNewline -ForegroundColor Green "IP Address: "
    Write-Host -ForegroundColor White $VCFInstallerIP
	Write-Host -NoNewline -ForegroundColor Green "vCPU: "
	Write-Host -ForegroundColor White $VCFInstallerVMvCPU
	Write-Host -NoNewline -ForegroundColor Green "vMEM: "
	Write-Host -ForegroundColor White "$VCFInstallerVMvMEM GB"

    if($deployNestedESXiVMsForMgmt -eq 1) {
        Write-Host -ForegroundColor Yellow "`n---- vESXi Configuration for $VCFInstallerProductSKU Management Domain ----"
        Write-Host -NoNewline -ForegroundColor Green "# of Nested ESXi VMs: "
        Write-Host -ForegroundColor White $NestedESXiHostnameToIPsForManagementDomain.count
        Write-Host -NoNewline -ForegroundColor Green "IP Address(s): "
        Write-Host -ForegroundColor White ($NestedESXiHostnameToIPsForManagementDomain.Values|Sort-Object)
        Write-Host -NoNewline -ForegroundColor Green "vCPU: "
        Write-Host -ForegroundColor White $NestedESXiMGMTvCPU
        Write-Host -NoNewline -ForegroundColor Green "vMEM: "
        Write-Host -ForegroundColor White "$NestedESXiMGMTvMEM GB"
        Write-Host -NoNewline -ForegroundColor Green "Caching VMDK: "
        Write-Host -ForegroundColor White "$NestedESXiMGMTCachingvDisk GB"
        Write-Host -NoNewline -ForegroundColor Green "Capacity VMDK: "
        Write-Host -ForegroundColor White "$NestedESXiMGMTCapacityvDisk GB"
    }

    if($deployNestedESXiVMsForWLD -eq 1) {
        Write-Host -ForegroundColor Yellow "`n---- vESXi Configuration for $VCFInstallerProductSKU Workload Domain ----"
        Write-Host -NoNewline -ForegroundColor Green "# of Nested ESXi VMs: "
        Write-Host -ForegroundColor White $NestedESXiHostnameToIPsForWorkloadDomain.count
        Write-Host -NoNewline -ForegroundColor Green "IP Address(s): "
        Write-Host -ForegroundColor White $NestedESXiHostnameToIPsForWorkloadDomain.Values
        Write-Host -NoNewline -ForegroundColor Green "vCPU: "
        Write-Host -ForegroundColor White $NestedESXiWLDvCPU
        Write-Host -NoNewline -ForegroundColor Green "vMEM: "
        Write-Host -ForegroundColor White "$NestedESXiWLDvMEM GB"
        Write-Host -NoNewline -ForegroundColor Green "Caching VMDK: "
        Write-Host -ForegroundColor White "$NestedESXiWLDCachingvDisk GB"
        Write-Host -NoNewline -ForegroundColor Green "Capacity VMDK: "
        Write-Host -ForegroundColor White "$NestedESXiWLDCapacityvDisk GB"
    }
	
    if($NSXuseExistingDeploymentNSX -eq 1 -and $deployNSXManager -eq 1) { 
        Write-Host -ForegroundColor Yellow "`n---- NSX Local Configurations----"
		Write-Host -NoNewline -ForegroundColor Green "NSX VIP Hostname/IP Address: "
		Write-Host -ForegroundColor White $NSXManagerVIPHostname $NSXManagerVIPIP
        Write-Host -NoNewline -ForegroundColor Green "NSX Hostname(s): "
        Write-Host -ForegroundColor White ($NSXManagerHostnameToIPsForManagementDomain.Keys|Sort-Object)
		Write-Host -NoNewline -ForegroundColor Green "NSX IP Address(s): "
		Write-Host -ForegroundColor White ($NSXManagerHostnameToIPsForManagementDomain.Values|Sort-Object)
        Write-Host -NoNewline -ForegroundColor Green "vCPU: "
        Write-Host -ForegroundColor White $NSXTMgrvCPU
        Write-Host -NoNewline -ForegroundColor Green "vMEM: "
        Write-Host -ForegroundColor White "$NSXTMgrvMEM GB"

    }

    Write-Host -ForegroundColor Yellow "`n---- Vlan Configuration for Management Domain ---- "
    Write-Host -NoNewline -ForegroundColor Green "Nested VM Network Vlan: "
    Write-Host -ForegroundColor White $NestedVMNetworkVLanId
    Write-Host -NoNewline -ForegroundColor Green "Nested ESXi Network Vlan: "
    Write-Host -ForegroundColor White $vmk0MgmtVLanId
    if($VCSAuseExistingDeploymentvCenter -eq 0) {
    Write-Host -NoNewline -ForegroundColor Green "Nested vMotion Network Vlan: "
    Write-Host -ForegroundColor White $vmotionVlanId
    }
    Write-Host -NoNewline -ForegroundColor Green "Nested vSAN Network Vlan: "
    Write-Host -ForegroundColor White $vsanVlanId
    Write-Host -NoNewline -ForegroundColor Green "Nested ESXi NSX TEP Network Vlan: "
    Write-Host -ForegroundColor White $esxiNSXTepVlanId
	
    Write-Host -ForegroundColor Yellow "`n---- Porgroups Configuration on Physical Host ---- "
    Write-Host -NoNewline -ForegroundColor Green "Nested ESXi PortGroup VMNetwork: "
    Write-Host -ForegroundColor White $VMNetwork
    Write-Host -NoNewline -ForegroundColor Green "VCF Installer PortGroup VCFInstallerNetwork: "
    Write-Host -ForegroundColor White $VCFInstallerNetwork

    Write-Host -ForegroundColor Yellow "`n---- Networks Configuration for Management Domain ---- "
    Write-Host -NoNewline -ForegroundColor Green "Nested VM Network: "
    Write-Host -ForegroundColor White $NestedVmManagementNetworkCidr
    Write-Host -NoNewline -ForegroundColor Green "Nested ESXi Network: "
    Write-Host -ForegroundColor White $NestedESXiManagementNetworkCidr
    if($VCSAuseExistingDeploymentvCenter -eq 0) {
    Write-Host -NoNewline -ForegroundColor Green "Nested VMOTION Network: "
    Write-Host -ForegroundColor White $NestedESXivMotionNetworkCidr
    }
    Write-Host -NoNewline -ForegroundColor Green "Nested VSAN Network: "
    Write-Host -ForegroundColor White $NestedESXivSANNetworkCidr
    Write-Host -NoNewline -ForegroundColor Green "Nested NSX TEP Network: "
    Write-Host -ForegroundColor White $NestedESXiNSXTepNetworkCidr
	
    Write-Host -NoNewline -ForegroundColor Green "`nNetmask "
    Write-Host -ForegroundColor White $VMNetmask
    Write-Host -NoNewline -ForegroundColor Green "VM Gateway: "
    Write-Host -ForegroundColor White $VMGateway
    Write-Host -NoNewline -ForegroundColor Green "ESXi Gateway Mgmt Domain: "
    Write-Host -ForegroundColor White $VMNestedESXiMgmtGateway
	if($deployNestedESXiVMsForWLD -eq 1) {
		Write-Host -NoNewline -ForegroundColor Green "Wld VM Gateway (documentation for NSX Edge VMs): "
		Write-Host -ForegroundColor White $VMWldGateway
		Write-Host -NoNewline -ForegroundColor Green "ESXi Gateway Wld Domain: "
		Write-Host -ForegroundColor White $VMNestedESXiWldGateway
	}
	Write-Host -NoNewline -ForegroundColor Green "VM Domain: "
	Write-Host -ForegroundColor White $VMDomain
    Write-Host -NoNewline -ForegroundColor Green "DNS: "
    Write-Host -ForegroundColor White $VMDNS
    Write-Host -NoNewline -ForegroundColor Green "NTP: "
    Write-Host -ForegroundColor White $VMNTP
    Write-Host -NoNewline -ForegroundColor Green "Syslog: "
    Write-Host -ForegroundColor White $VMSyslog

	if($VCSAclusterEvcMode -ne "$null"){
		Write-Host -ForegroundColor Yellow "`n---- Nested vCenter Configuration for Management Domain ---- "
		Write-Host -NoNewline -ForegroundColor Green "Cluster EVC Mode: "
		Write-Host -ForegroundColor White $VCSAclusterEvcMode
	}

    Write-Host -ForegroundColor Magenta "`nWould you like to proceed with this deployment?`n"
    $answer = Read-Host -Prompt "Do you accept (Y or N)"
    if($answer -ne "Y" -and $answer -ne "y") {
        exit
    }
    Clear-Host
}

if($deployNestedESXiVMsForMgmt -eq 1 -or $restartNestedMgmtVM -eq 1 -or $updateVCFInstallerConfig -eq 1 -or $deployVCFInstaller -eq 1 -or $moveVMsIntovApp -eq 1) {
    My-Logger "Connecting to Management vCenter Server $VIServer ..."
    $viConnection = Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue
	$WarningPreference = 'SilentlyContinue'
    $datastore = Get-Datastore -Server $viConnection -Name $VMDatastoreMGMT | Select-Object -First 1
    $cluster = Get-Cluster -Server $viConnection -Name $VMCluster
    $vmhost = $cluster | Get-VMHost -Datastore $datastore | Get-Random -Count 1
	$rp = Get-ResourcePool -Name Resources -Location $cluster
}

if($deployVCFInstaller -eq 1) {
    $ovfconfig = Get-OvfConfiguration $VCFInstallerOVA

    $networkMapLabel = ($ovfconfig.ToHashTable().keys | Where-Object {$_ -Match "NetworkMapping"}).replace("NetworkMapping.","").replace("-","_").replace(" ","_")
    $ovfconfig.NetworkMapping.$networkMapLabel.value = $VCFInstallerNetwork
    $ovfconfig.Common.vami.hostname.value = $VCFInstallerFQDN
    $ovfconfig.vami.SDDC_Manager.ip0.value = $VCFInstallerIP
    $ovfconfig.vami.SDDC_Manager.netmask0.value = $VMNetmask
    $ovfconfig.vami.SDDC_Manager.gateway.value = $VMGateway
    $ovfconfig.vami.SDDC_Manager.DNS.value = $VMDNS
    $ovfconfig.vami.SDDC_Manager.domain.value = $VMDomain
    $ovfconfig.vami.SDDC_Manager.searchpath.value = $VMDomain
    $ovfconfig.common.guestinfo.ntp.value = $VMNTP
    $ovfconfig.Common.LOCAL_USER_PASSWORD.value = $VCFInstallerAdminPassword
    $ovfconfig.Common.ROOT_PASSWORD.value = $VCFInstallerRootPassword

    My-Logger "Deploying VCF Installer VM $VCFInstallerVMName ..."
    try {
        $vm = Import-VApp -Server $viConnection -Source $VCFInstallerOVA -OvfConfiguration $ovfconfig -Name $VCFInstallerVMName -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin -Location $VMCluster | Out-Null
        $vm = Get-VM -Server $viConnection -Name $VCFInstallerVMName -Location $VMCluster  | Where-Object {$_.ResourcePool.Id -eq $rp.Id} 
    } catch {
        My-Logger "Failed to deploy $VCFInstallerVMName ..."
        Disconnect-VIServer -Server $viConnection -Confirm:$false
        exit
    }

    My-Logger "Updating Virtual Hardware compute for VCF Installer VM (vCPU=${VCFInstallerVMvCPU} vMEM=${VCFInstallerVMvMEM}GB) ..."
    Set-VM -Server $viConnection -VM $vm -NumCpu $VCFInstallerVMvCPU -CoresPerSocket $VCFInstallerVMvCPU -MemoryGB $VCFInstallerVMvMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

    My-Logger "Powering On $VCFInstallerVMName ..."
    $vm | Start-Vm | Out-Null
}

if($updateVCFInstallerConfig -eq 1) {
    My-Logger "Waiting for VCF Installer UI to be ready ..."
    while(1) {
        try {
            $requests = Invoke-WebRequest -Uri "https://${VCFInstallerFQDN}/vcf-installer-ui/login" -Method GET -SkipCertificateCheck -TimeoutSec 5
            if($requests.StatusCode -eq 200) {
                My-Logger "`tVCF Installer UI https://${VCFInstallerFQDN}/vcf-installer-ui/login is now ready!"
                break
            }
        }
        catch {
            My-Logger "VCF Installer UI is not ready yet, sleeping for 5 min ..."
            Start-Sleep 300
        }
    }

    $scriptName = "vcfIntScript.sh"
    $script = @"
#!/bin/bash
# Generated by William Lam's VCF 9 Automated Deployment Lab Script


"@

    if($VCFDomainManagerProperties -ne $null) {
        $vcfDomainConfigFile = "/etc/vmware/vcf/domainmanager/application.properties"
        $VCFDomainManagerProperties.GetEnumerator() | Foreach-Object {
            $script += "echo $($_.key)=$($_.value) >> ${vcfDomainConfigFile}`n"
        }
    }

    if($VCFFeatureProperties -ne $null) {
        $vcfFeatureConfigFile = "/home/vcf/feature.properties"
        $VCFFeatureProperties.GetEnumerator() | Foreach-Object {
            $script += "echo $($_.key)=$($_.value) >> ${vcfFeatureConfigFile}`n"
        }
        $script += "chmod 755 ${vcfFeatureConfigFile}`n"
    }

    if($VCFInstallerSoftwareDepot -eq "offline") {
        $vcfLcmConfigFile = "/opt/vmware/vcf/lcm/lcm-app/conf/application-prod.properties"

        if($VCFInstallerDepotHttps -eq $false) {
            $script += "sed -i -e `"/lcm.depot.adapter.port=.*/a lcm.depot.adapter.httpsEnabled=false`" ${vcfLcmConfigFile}`n"
        }
    }

    if($VCSAuseExistingDeploymentvCenter -eq 1 -and $NestedESXiHostnameToIPsForManagementDomain.count -lt 3) {
        # Remove Guardrail 3 nodes VSAN requirements if less than 3 ESXi nodes are actively used in the sample (non-actively used hostname/IP can be commented)
		$script += "vsan=""conforming-cluster-present-check""`n"
		$script += "jq --arg vsan `$vsan` 'del(.children[]?.externalValidations[]? | select(.id == `$vsan`))' /opt/vmware/vcf/operationsmanager/scripts/assessment/guardrails/operations/import/import.json >import.tmp && mv import.tmp /opt/vmware/vcf/operationsmanager/scripts/assessment/guardrails/operations/import/import.json`n"
    }
    
    if($VCSAuseExistingDeploymentvCenter -eq 1 -and $NSXuseExistingDeploymentNSX -eq 1 -and $NSXManagerHostnameToIPsForManagementDomain.count -lt 3) {
        # Remove Guardrail 3 nodes NSX requirements if less than 3 NSX nodes are actively used in the sample (non-actively used hostname/IP can be commented)
		$script += "nsx=""import-existing-nsxt-cluster-size""`n"
        $script += "jq --arg nsx `$nsx` 'del(.constraints[]? | select(.id == `$nsx`))' /opt/vmware/vcf/operationsmanager/scripts/assessment/guardrails/common/resourcestates/nsx-import-base.json >nsx-import-base.tmp && mv nsx-import-base.tmp /opt/vmware/vcf/operationsmanager/scripts/assessment/guardrails/common/resourcestates/nsx-import-base.json`n"
    }

    $script += "echo 'y' | '/opt/vmware/vcf/operationsmanager/scripts/cli/sddcmanager_restart_services.sh'`n"
    $script | Out-File $scriptName

	My-Logger "Transfering configuration shell script ($scriptName) to VCF Installer VM (in case of reusing the same Lab vApp be aware to set this variable updateVCFInstallerConfig = 0) ..."
	$vcfVM = Get-VM -Name $VCFInstallerVMName -Server $viConnection -Location $cluster  | Where-Object {$_.ResourcePool.Id -eq $rp.Id} 
	Copy-VMGuestFile -Server $viConnection -VM $vcfVM -GuestUser "root" -GuestPassword $VCFInstallerRootPassword -LocalToGuest -Source ${scriptName} -Destination /tmp/$scriptName | Out-Null
	My-Logger "Running configuration shell script on VCF Installer VM ..."
	Invoke-VMScript -ScriptText "bash /tmp/${scriptName}" -VM $vcfVM -GuestUser "root" -GuestPassword $VCFInstallerRootPassword -ScriptType Bash | Out-Null

    Start-Sleep -Seconds 120
}

if($deployNestedESXiVMsForMgmt -eq 1) {
    $NestedESXiHostnameToIPsForManagementDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $VMName = $_.Key
        $VMIPAddress = $_.Value

        $ovfconfig = Get-OvfConfiguration $NestedESXiApplianceOVA
        $networkMapLabel = ($ovfconfig.ToHashTable().keys | Where-Object {$_ -Match "NetworkMapping"}).replace("NetworkMapping.","").replace("-","_").replace(" ","_")
        $ovfconfig.NetworkMapping.$networkMapLabel.value = $VMNetwork
        if($setVLanId -eq 1) {
            $ovfconfig.common.guestinfo.vlan.value = $vmk0MgmtVLanId
        }
        $ovfconfig.common.guestinfo.hostname.value = "${VMName}.${VMDomain}"
        $ovfconfig.common.guestinfo.ipaddress.value = $VMIPAddress
        $ovfconfig.common.guestinfo.netmask.value = $VMNetmask
        $ovfconfig.common.guestinfo.gateway.value = $VMNestedESXiMgmtGateway
        $ovfconfig.common.guestinfo.dns.value = $VMDNS
        $ovfconfig.common.guestinfo.domain.value = $VMDomain
        $ovfconfig.common.guestinfo.ntp.value = $VMNTP
        $ovfconfig.common.guestinfo.syslog.value = $VMSyslog
        $ovfconfig.common.guestinfo.password.value = $VMPassword
        $ovfconfig.common.guestinfo.ssh.value = $true

        My-Logger "Deploying Nested ESXi VM $VMName ..."
        try {
            Import-VApp -Server $viConnection -Source $NestedESXiApplianceOVA -OvfConfiguration $ovfconfig -Name $VMName -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin -Location $VMCluster | Out-Null
            $vm = Get-VM -Server $viConnection -Name $VMName -Location $VMCluster | Where-Object {$_.ResourcePool.Id -eq $rp.Id} 
        } catch {
            My-Logger "Failed to deploy $VMName ..."
            Disconnect-VIServer -Server $viConnection -Confirm:$false
            exit
        }

        My-Logger "Updating Virtual Hardware compute for Nested ESXi VMs (vCPU=${NestedESXiMGMTvCPU} vMEM=${NestedESXiMGMTvMEM}GB vGuestOS=${NestedESXiMGMTvGuestOS} vHardwareVersion=${NestedESXiMGMTvHardwareVersion}) ..."
        Set-VM -Server $viConnection -VM $vm -NumCpu $NestedESXiMGMTvCPU -CoresPerSocket $NestedESXiMGMTvCPU -MemoryGB $NestedESXiMGMTvMEM -GuestId $NestedESXiMGMTvGuestOS -HardwareVersion $NestedESXiMGMTvHardwareVersion -Confirm:$false -ErrorAction Ignore | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating Virtual Hardware storage for Nested ESXi VMs (Boot Disk=${NestedESXiMGMTBootDisk}GB vSAN Cache=${NestedESXiMGMTCachingvDisk}GB vSAN Capacity=${NestedESXiMGMTCapacityvDisk}GB) ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 1" | Set-HardDisk -CapacityGB $NestedESXiMGMTBootDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 2" | Set-HardDisk -CapacityGB $NestedESXiMGMTCachingvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 3" | Set-HardDisk -CapacityGB $NestedESXiMGMTCapacityvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating Virtual Hardware networking for Nested ESXi VMs (Adding vmnic2/vmnic3) ..."
        $vmPortGroup = Get-VirtualNetwork -Name $VMNetwork -Location ($cluster | Get-Datacenter)
        if($vmPortGroup.NetworkType -eq "Distributed") {
            $vmPortGroup = Get-VDPortgroup -Server $viConnection | Where-Object {($_.Name -match "$VMNetwork")} 
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        } else {
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }

        $vm | New-AdvancedSetting -name "ethernet2.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet2.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        $vm | New-AdvancedSetting -name "ethernet3.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet3.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        
        $vm | New-AdvancedSetting -Name "sched.mem.enableNestedTiering" -value "TRUE" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Powering On $vmname ..."
        $vm | Start-Vm | Out-Null
    }
    Start-Sleep -Seconds 120
}

if($restartNestedMgmtVM -eq 1) {
    if($deployNestedESXiVMsForMgmt -eq 1) {
        $NestedESXiHostnameToIPsForManagementDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
            $VMName = $_.Key
            $VMIPAddress = $_.Value
            $vm = Get-VM -Server $viConnection -Name $VMName -Location $VMCluster | Where-Object {$_.ResourcePool.Id -eq $rp.Id}
            do {	
                My-Logger "Setup service NTP to start with ESX and restart guest OS of $VMName ..."
                $ping = Test-Connection $VMIPAddress -Quiet
            } until ($ping -contains "True")
            Get-VMHost -VM $vm | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "on"  | Out-File -Append -LiteralPath $verboseLogFile
			Get-VMHost -VM $vm | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService  | Out-File -Append -LiteralPath $verboseLogFile
			Start-Sleep -Seconds 120
            $vm | Restart-VMGuest -confirm:$false | Out-Null
        }
    }
}

if($deployNestedESXiVMsForWLD -eq 1 -or $restartNestedWldVM -eq 1) {
    My-Logger "Connecting to Management vCenter Server $VIServer ..."
    $viConnection = Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue
	$WarningPreference = 'SilentlyContinue'
    $datastore = Get-Datastore -Server $viConnection -Name $VMDatastoreWLD | Select-Object -First 1
    $cluster = Get-Cluster -Server $viConnection -Name $VMCluster
	$vmhost = $cluster | Get-VMHost -Datastore $datastore | Get-Random -Count 1
	$rp = Get-ResourcePool -Name Resources -Location $cluster
}

if($deployNestedESXiVMsForWLD -eq 1) {
    $NestedESXiHostnameToIPsForWorkloadDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $VMName = $_.Key
        $VMIPAddress = $_.Value

        $ovfconfig = Get-OvfConfiguration $NestedESXiApplianceOVA
        $networkMapLabel = ($ovfconfig.ToHashTable().keys | Where-Object {$_ -Match "NetworkMapping"}).replace("NetworkMapping.","").replace("-","_").replace(" ","_")
        $ovfconfig.NetworkMapping.$networkMapLabel.value = $VMNetwork
		if($setVLanId -eq 1) {
            $ovfconfig.common.guestinfo.vlan.value = $vmk0WldVLanId
        }
        $ovfconfig.common.guestinfo.hostname.value = "${VMName}.${VMDomain}"
        $ovfconfig.common.guestinfo.ipaddress.value = $VMIPAddress
        $ovfconfig.common.guestinfo.netmask.value = $VMNetmask
        $ovfconfig.common.guestinfo.gateway.value = $VMNestedESXiWldGateway
        $ovfconfig.common.guestinfo.dns.value = $VMDNS
        $ovfconfig.common.guestinfo.domain.value = $VMDomain
        $ovfconfig.common.guestinfo.ntp.value = $VMNTP
        $ovfconfig.common.guestinfo.syslog.value = $VMSyslog
        $ovfconfig.common.guestinfo.password.value = $VMPassword
        $ovfconfig.common.guestinfo.ssh.value = $true

        My-Logger "Deploying Nested ESXi VM $VMName ..."
        try {
            Import-VApp -Server $viConnection -Source $NestedESXiApplianceOVA -OvfConfiguration $ovfconfig -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin -Name $VMName -Location $VMCluster | Out-Null
            $vm = Get-VM -Server $viConnection -Name $VMName -Location $VMCluster | Where-Object {$_.ResourcePool.Id -eq $rp.Id} 
        } catch {
            My-Logger "Failed to deploy $VMName ..."
            Disconnect-VIServer -Server $viConnection -Confirm:$false
            exit
        }

        My-Logger "Updating Virtual Hardware compute for Nested ESXi VMs (vCPU=${NestedESXiWLDvCPU} vMEM=${NestedESXiWLDvMEM}GB) ..."
        Set-VM -Server $viConnection -VM $vm -NumCpu $NestedESXiWLDvCPU -CoresPerSocket $NestedESXiWLDvCPU -MemoryGB $NestedESXiWLDvMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating Virtual Hardware storage for Nested ESXi VMs (Boot Disk=${NestedESXiWLDBootDisk}GB vSAN Cache=${NestedESXiWLDCachingvDisk}GB vSAN Capacity=${NestedESXiWLDCapacityvDisk}GB) ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 1" | Set-HardDisk -CapacityGB $NestedESXiWLDBootDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 2" | Set-HardDisk -CapacityGB $NestedESXiWLDCachingvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 3" | Set-HardDisk -CapacityGB $NestedESXiWLDCapacityvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating Virtual Hardware networking for Nested ESXi VMs (Adding vmnic2/vmnic3) ..."
        $vmPortGroup = Get-VirtualNetwork -Name $VMNetwork -Location ($cluster | Get-Datacenter)
        if($vmPortGroup.NetworkType -eq "Distributed") {
            $vmPortGroup = Get-VDPortgroup -Server $viConnection | Where-Object {($_.Name -match "$VMNetwork")}
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        } else {
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }

        $vm | New-AdvancedSetting -name "ethernet2.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet2.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        $vm | New-AdvancedSetting -name "ethernet3.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet3.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        
        $vm | New-AdvancedSetting -Name "sched.mem.enableNestedTiering" -value "TRUE" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Powering On $vmname ..."
        $vm | Start-Vm | Out-Null
    }
}

if($restartNestedWldVM -eq 1) {
    if($deployNestedESXiVMsForWLD -eq 1) {
        $NestedESXiHostnameToIPsForWorkloadDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
            $VMName = $_.Key
            $VMIPAddress = $_.Value
            $vm = Get-VM -Server $viConnection -Name $VMName -Location $VMCluster | Where-Object {$_.ResourcePool.Id -eq $rp.Id}
            do {	
                My-Logger "wait Initiate guest OS reboot of $VMName  ..."
                $ping = Test-Connection $VMIPAddress -Quiet
            } until ($ping -contains "True")
            Get-VMHost -VM $vm | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "on"  | Out-File -Append -LiteralPath $verboseLogFile
			Get-VMHost -VM $vm | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService  | Out-File -Append -LiteralPath $verboseLogFile
			Start-Sleep -Seconds 120
            $vm | Restart-VmGuest -confirm:$false | Out-Null
        }
    }
}
Start-Sleep -Seconds 90

if($setVLanId -eq 1) {
	if($deployNestedESXiVMsForMgmt -eq 1) {
		$NestedESXiHostnameToIPsForManagementDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
            $VMName = $_.Key
            $VMIPAddress = $_.Value
            $targetVMHost = $VMIPAddress
            
            do {	
            My-Logger "Waiting for $targetVMHost to be ready on network ..."
            $ping = Test-Connection $targetVMHost -Quiet
            Start-Sleep 60
            } until ($ping -contains "True")
            
            $viConnectionESXiMgmt = Connect-VIServer $targetVMHost -User "root" -Password $VMPassword  -WarningAction SilentlyContinue
            My-Logger "Setting VLAN ID $NestedVMNetworkVLanId for VM Network"
            Get-VirtualPortgroup -Server $viConnectionESXiMgmt -Name "VM Network" | Set-VirtualPortgroup -VLanId $NestedVMNetworkVLanId | Out-File -Append -LiteralPath $verboseLogFile
		}
    }
	if($deployNestedESXiVMsForWLD -eq 1) {
		$NestedESXiHostnameToIPsForWorkloadDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
            $VMName = $_.Key
            $VMIPAddress = $_.Value
            $targetVMHost = $VMIPAddress
            
            do {	
            My-Logger "Waiting for $targetVMHost to be ready on network ..."
            $ping = Test-Connection $targetVMHost -Quiet
            Start-Sleep 60
            } until ($ping -contains "True")
            
            $viConnectionESXiWld = Connect-VIServer $targetVMHost -User "root" -Password $VMPassword  -WarningAction SilentlyContinue 
            My-Logger "Setting VLAN ID $NestedVMNetworkVLanId for VM Network"
            Get-VirtualPortgroup -Server $viConnectionESXiWld -Name "VM Network" | Set-VirtualPortgroup -VLanId $NestedVMNetworkVLanId | Out-File -Append -LiteralPath $verboseLogFile
		}
	}
}

if( $setupEntropy -eq 1) {
    if($deployNestedESXiVMsForMgmt -eq 1) {
		My-Logger "Setting Entropy on Management Domain hosts..."
		$NestedESXiHostnameToIPsForManagementDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
			$VMName = $_.Key
			$VMIPAddress = $_.Value
			$targetVMHost = $VMIPAddress
			
			do {	
			My-Logger "Waiting for $targetVMHost to be ready on network ..."
			$ping = Test-Connection $targetVMHost -Quiet
			Start-Sleep 60
			} until ($ping -contains "True")
			
			My-Logger "Connecting to ESXi $targetVMHost node ..."
			$vEsxi = Connect-VIServer -Server $targetVMHost -User root -Password $VMPassword -WarningAction SilentlyContinue
			$esxcli = Get-EsxCli -Server $vEsxi -V2
			My-Logger "Update entropy sources to using $entropySourcesMGMT"
			$kernargs=$esxcli.system.settings.kernel.set.CreateArgs()
			$kernargs.setting = "entropySources"
			$kernargs.value = $entropySourcesMGMT
			$esxcli.system.settings.kernel.set.Invoke($kernargs) | Out-File -Append -LiteralPath $verboseLogFile
			sleep 30
			My-Logger "Rebooting ESXi $targetVMHost ..."
			Restart-VMHost -VMHost $targetVMHost -Server $vEsxi -confirm:$false -force -RunAsync -ErrorAction Ignore | Out-File -Append -LiteralPath $verboseLogFile
			
			My-Logger "Disconnecting from $targetVMHost ..."
			Disconnect-VIServer -Server $vEsxi -Confirm:$false
		}
	}
	if($deployNestedESXiVMsForWLD -eq 1) {
		My-Logger "Setting Entropy on Workload Domain hosts..."
		$NestedESXiHostnameToIPsForWorkloadDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
			$VMName = $_.Key
			$VMIPAddress = $_.Value
			$targetVMHost = $VMIPAddress
			
			do {	
			My-Logger "Waiting for $targetVMHost to be ready on network ..."
			$ping = Test-Connection $targetVMHost -Quiet
			Start-Sleep 60
			} until ($ping -contains "True")
			
			My-Logger "Connecting to ESXi $targetVMHost node ..."
			$vEsxi = Connect-VIServer -Server $targetVMHost -User root -Password $VMPassword -WarningAction SilentlyContinue
			$esxcli = Get-EsxCli -Server $vEsxi -V2
			My-Logger "Update entropy sources to using $entropySourcesWLD"
			$kernargs=$esxcli.system.settings.kernel.set.CreateArgs()
			$kernargs.setting = "entropySources"
			$kernargs.value = $entropySourcesWLD
			$esxcli.system.settings.kernel.set.Invoke($kernargs) | Out-File -Append -LiteralPath $verboseLogFile
			sleep 30
			My-Logger "Rebooting ESXi $targetVMHost ..."
			Restart-VMHost -VMHost $targetVMHost -Server $vEsxi -confirm:$false -force -RunAsync -ErrorAction Ignore | Out-File -Append -LiteralPath $verboseLogFile
			
			My-Logger "Disconnecting from $targetVMHost ..."
			Disconnect-VIServer -Server $vEsxi -Confirm:$false
		}
	}
}

if($deployNestedESXiVMsForMgmt -eq 1 -or $restartNestedMgmtVM -eq 1 -or $deployNestedESXiVMsForWLD -eq 1 -or $restartNestedWldVM -eq 1 -or $setVLanId -eq 1) {
    My-Logger "Disconnecting from all servers connections..."
    Disconnect-VIServer -Server $viConnection -Confirm:$false
}

# Trigger VSAN bootstrap for Management Domain
if($bootStrapFirstNestedESXiVM -eq 1) {
    do {
        My-Logger "Waiting for $bootStrapNode to be ready on network ..."
        $ping = Test-Connection $bootStrapNode -Quiet
        Start-Sleep 60
    } until ($ping -contains "true")

    My-Logger "Connecting to ESXi bootstrap node ..."
    $vEsxi = Connect-VIServer -Server $bootStrapNode -User root -Password $VMPassword -WarningAction SilentlyContinue

    My-Logger "Updating the ESXi host VSAN Policy to allow Force Provisioning ..."
    $esxcli = Get-EsxCli -Server $vEsxi -V2
    $VSANPolicy = '(("hostFailuresToTolerate" i0) ("forceProvisioning" i1))'
    $VSANPolicyDefaults = $esxcli.vsan.policy.setdefault.CreateArgs()
    $VSANPolicyDefaults.policy = $VSANPolicy
    $VSANPolicyDefaults.policyclass = "vdisk"
    $esxcli.vsan.policy.setdefault.Invoke($VSANPolicyDefaults) | Out-File -Append -LiteralPath $verboseLogFile
    $VSANPolicyDefaults.policyclass = "vmnamespace"
    $esxcli.vsan.policy.setdefault.Invoke($VSANPolicyDefaults) | Out-File -Append -LiteralPath $verboseLogFile

    My-Logger "Creating a single node VSAN Cluster"
    $esxcli.vsan.cluster.new.Invoke() | Out-File -Append -LiteralPath $verboseLogFile

    $luns = Get-ScsiLun -Server $vEsxi | select CanonicalName, CapacityGB

    My-Logger "Querying ESXi host disks to create VSAN Diskgroups ..."
    foreach ($lun in $luns) {
        if(([int]($lun.CapacityGB)).toString() -eq "$NestedESXiMGMTCachingvDisk") {
            $vsanCacheDisk = $lun.CanonicalName
        }
        if(([int]($lun.CapacityGB)).toString() -eq "$NestedESXiMGMTCapacityvDisk") {
            $vsanCapacityDisk = $lun.CanonicalName
        }
    }

    My-Logger "Tagging Capacity Disk ..."
    $capacitytag = $esxcli.vsan.storage.tag.add.CreateArgs()
    $capacitytag.disk = $vsanCapacityDisk
    $capacitytag.tag = "capacityFlash"
    $esxcli.vsan.storage.tag.add.Invoke($capacitytag) | Out-File -Append -LiteralPath $verboseLogFile

    My-Logger "Creating VSAN Diskgroup ..."
    $addvsanstorage = $esxcli.vsan.storage.add.CreateArgs()
    $addvsanstorage.ssd = $vsanCacheDisk
    $addvsanstorage.disks = $vsanCapacityDisk
    $esxcli.vsan.storage.add.Invoke($addvsanstorage) | Out-File -Append -LiteralPath $verboseLogFile

    My-Logger "Disconnecting from $vEsxi ..."
    Disconnect-VIServer -Server $vEsxi -Confirm:$false
}

# vCSA deployment and configuration, for VCF Converge workflow of existing vCenter
if( $VCSAuseExistingDeploymentvCenter -eq 1) {
    if($deployVCSA -eq 1) {
        if($IsWindows) {
            $config = (Get-Content -Raw "$($VCSAInstallerPath)\vcsa-cli-installer\templates\install\embedded_vCSA_on_ESXi.json") | convertfrom-json
        } else {
            $config = (Get-Content -Raw "$($VCSAInstallerPath)/vcsa-cli-installer/templates/install/embedded_vCSA_on_ESXi.json") | convertfrom-json
        }

        $vcsaFQDN = $VCSAName + "." + $VMDomain
        $esxiFQDN = $bootStrapNode + "." + $VMDomain

        $config.'new_vcsa'.esxi.hostname = $esxiFQDN
        $config.'new_vcsa'.esxi.username = "root"
        $config.'new_vcsa'.esxi.password = $VMPassword
        $config.'new_vcsa'.esxi.deployment_network = "VM Network"
        $config.'new_vcsa'.esxi.datastore = "vsanDatastore"
        $config.'new_vcsa'.appliance.thin_disk_mode = $true
        $config.'new_vcsa'.appliance.deployment_option = $VCSASize
        $config.'new_vcsa'.appliance.name = $VCSAName
        $config.'new_vcsa'.network.ip_family = "ipv4"
        $config.'new_vcsa'.network.mode = "static"
        $config.'new_vcsa'.network.ip = $VCSAIP
        $config.'new_vcsa'.network.dns_servers[0] = $VMDNS
        $config.'new_vcsa'.network.prefix = $VCSAPrefix
        $config.'new_vcsa'.network.gateway = $VMGateway
        $config.'new_vcsa'.os.ntp_servers = $VMNTP
        $config.'new_vcsa'.network.system_name = $vcsaFQDN
        $config.'new_vcsa'.os.password = $VCSARootPassword
        $config.'ceip'.settings.ceip_enabled = $CEIPEnabled
        if($VCSASSHEnable -eq "true") {
            $VCSASSHEnableVar = $true
        } else {
            $VCSASSHEnableVar = $false
        }
        $config.'new_vcsa'.os.ssh_enable = $VCSASSHEnableVar
        $config.'new_vcsa'.sso.password = $VCSASSOPassword
        $config.'new_vcsa'.sso.domain_name = $VCSASSODomainName

        if($IsWindows) {
            My-Logger "Creating VCSA JSON Configuration file for deployment ..."
            $config | ConvertTo-Json -WarningAction Ignore | Set-Content -Path "$($ENV:Temp)\jsontemplate.json"

            My-Logger "Deploying VCSA to Nested ESXi VM ..."
            My-Logger "... this will take a while, go grab a drink 🍵🍺🍷"
			$WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            $PSNativeCommandUseErrorActionPreference = $true
            Invoke-Expression "$($VCSAInstallerPath)\vcsa-cli-installer\win32\vcsa-deploy.exe install --no-esx-ssl-verify --accept-eula --acknowledge-ceip $($ENV:Temp)\jsontemplate.json" -WarningAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        } elseif($IsMacOS) {
            My-Logger "Creating VCSA JSON Configuration file for deployment ..."
            $config | ConvertTo-Json -WarningAction Ignore | Set-Content -Path "$($ENV:TMPDIR)jsontemplate.json"

            My-Logger "Deploying VCSA to Nested ESXi VM ..."
            My-Logger "... this will take a while, go grab a drink 🍵🍺🍷"
			$WarningPreference = 'SilentlyContinue'
            Invoke-Expression "$($VCSAInstallerPath)/vcsa-cli-installer/mac/vcsa-deploy install --no-esx-ssl-verify --accept-eula --acknowledge-ceip $($ENV:TMPDIR)jsontemplate.json"| Out-File -Append -LiteralPath $verboseLogFile
        } elseif ($IsLinux) {
            My-Logger "Creating VCSA JSON Configuration file for deployment ..."
            $config | ConvertTo-Json -WarningAction Ignore| Set-Content -Path "/tmp/jsontemplate.json"

            My-Logger "Deploying VCSA to Nested ESXi VM ..."
            My-Logger "... this will take a while, go grab a drink 🍵🍺🍷"
			$WarningPreference = 'SilentlyContinue'
            Invoke-Expression "$($VCSAInstallerPath)/vcsa-cli-installer/lin64/vcsa-deploy install --no-esx-ssl-verify --accept-eula --acknowledge-ceip /tmp/jsontemplate.json"| Out-File -Append -LiteralPath $verboseLogFile
        }
    }

    if($setupNewVC -eq 1) {
        My-Logger "Connecting to the new VCSA ..."
        $vc = Connect-VIServer $VCSAIP -User $VCSASSOUserName -Password $VCSASSOPassword -WarningAction SilentlyContinue

        $d = Get-Datacenter $VCSADatacenterName -Server $vc -ErrorAction Ignore
        if( -Not $d) {
            My-Logger "Creating Datacenter $VCSADatacenterName ..."
            New-Datacenter -Name $VCSADatacenterName -Server $vc -Location (Get-Folder -Type Datacenter -Server $vc) | Out-File -Append -LiteralPath $verboseLogFile
        }
        
        $ESXVMHost = $bootStrapNode + "." + $VMDomain
        $ESXURL = "https://" + $ESXVMHost + ":443"
        $ESXThumbprint = Get-SSLThumbprint -URL $ESXURL
        $i = Get-LCMImage -Version $VCSAVLCMversion -Type BaseImage -Server $vc -ErrorAction Ignore
        if( -Not $i) {
            My-Logger "Extract and import vSphere Lifecycle Manager Images from first deployed ESXi $bootStrapNode, Waiting 5 min to complete ..."
            $SettingsDepotsOfflineHostCredentials = Initialize-SettingsDepotsOfflineHostCredentials -HostName $ESXVMHost -UserName "root" -Password $VMPassword -Port 443 -SslThumbPrint $ESXThumbprint
            $SettingsDepotsOfflineConnectionSpec = Initialize-SettingsDepotsOfflineConnectionSpec -AuthType "USERNAME_PASSWORD" -HostCredential $SettingsDepotsOfflineHostCredentials
            Invoke-CreateFromHostDepotsOfflineAsync -SettingsDepotsOfflineConnectionSpec $SettingsDepotsOfflineConnectionSpec -Confirm:$false -ErrorAction Ignore | Out-File -Append -LiteralPath $verboseLogFile

            Start-Sleep 300

            $vLCMBaseImage = Get-LCMImage -Version $VCSAVLCMversion -Type BaseImage -Server $vc
        }
        
        $c = Get-Cluster $VCSAClusterName -Server $vc -ErrorAction Ignore
        if( -Not $c) {
        
            My-Logger "Creating VSAN Cluster $VCSAClusterName with vLCM image version $VCSAVLCMversion ..."
            New-Cluster -Name $VCSAClusterName -Server $vc -Location (Get-Datacenter -Name $VCSADatacenterName -Server $vc) -BaseImage $vLCMBaseImage -DrsEnabled -DrsAutomationLevel Manual -HAEnabled -VsanEnabled | Out-File -Append -LiteralPath $verboseLogFile

            (Get-Cluster $VCSAClusterName -Server $vc) | New-AdvancedSetting -Name "das.ignoreRedundantNetWarning" -Type ClusterHA -Value $true -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }

        if($addESXiHostsToVC -eq 1) {
            $NestedESXiHostnameToIPsForManagementDomain.GetEnumerator() | Sort-Object -Property Key | Foreach-Object {
                $VMName = $_.Key
                $VMIPAddress = $_.Value

                $targetVMHost = $VMName + "." + $VMDomain

                My-Logger "Adding ESXi host $targetVMHost to Cluster ..."
                Add-VMHost -Server $vc -Location (Get-Cluster -Name $VCSAClusterName -Server $vc) -User "root" -Password $VMPassword -Name $targetVMHost -Force | Out-File -Append -LiteralPath $verboseLogFile
            }

            $haRuntime = (Get-Cluster $VCSAClusterName -Server $vc).ExtensionData.RetrieveDasAdvancedRuntimeInfo
            $totalHaHosts = $haRuntime.TotalHosts
            $totalHaGoodHosts = $haRuntime.TotalGoodHosts
            while($totalHaGoodHosts -ne $totalHaHosts) {
                My-Logger "Waiting for vSphere HA configuration to complete ..."
                Start-Sleep -Seconds 60
                $haRuntime = (Get-Cluster $VCSAClusterName -Server $vc).ExtensionData.RetrieveDasAdvancedRuntimeInfo
                $totalHaHosts = $haRuntime.TotalHosts
                $totalHaGoodHosts = $haRuntime.TotalGoodHosts
            }
        }
        
        if($configureVSANDiskGroup -eq 1) {
            My-Logger "Enabling VSAN & disabling VSAN Health Check ..."
            Get-VsanClusterConfiguration -Cluster $VCSAClusterName -Server $vc| Set-VsanClusterConfiguration -HealthCheckIntervalMinutes 0 | Out-File -Append -LiteralPath $verboseLogFile

            foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
                if($vmhost.name -notmatch $bootStrapNode) {
                    $luns = $vmhost | Get-ScsiLun | select CanonicalName, CapacityGB

                    My-Logger "Querying ESXi host disks to create VSAN Diskgroups ..."
                    foreach ($lun in $luns) {
                        if(([int]($lun.CapacityGB)).toString() -eq "$NestedESXiMGMTCachingvDisk") {
                            $vsanCacheDisk = $lun.CanonicalName
                        }
                        if(([int]($lun.CapacityGB)).toString() -eq "$NestedESXiMGMTCapacityvDisk") {
                            $vsanCapacityDisk = $lun.CanonicalName
                        }
                    }
                    My-Logger "Creating VSAN DiskGroup for $vmhost ..."
                    New-VsanDiskGroup -Server $vc -VMHost $vmhost -SsdCanonicalName $vsanCacheDisk -DataDiskCanonicalName $vsanCapacityDisk | Out-File -Append -LiteralPath $verboseLogFile
                }
            }
        }
        
        #Start-Sleep -Seconds 120
        
        if($setupVsanStoragePolicy -eq 1) {
            $datastore = Get-Datastore -Name $VSANDatastoreName -Server $vc | Select-Object -First 1
            My-Logger "Creating VSAN Storage Policies $VSANStoragePolicyName and attaching to $datastore ..."
            $fttcap = Get-SpbmCapability -Name "VSAN.hostFailuresToTolerate" -Server $vc
            $fttRule = New-SpbmRule -Capability ($fttcap) -Value $VSANFTT -Server $vc
            $fttRuleSet = New-SpbmRuleSet -AllOfRules $fttRule -ErrorAction SilentlyContinue
            $fttVsanPolicy = New-SpbmStoragePolicy -Name $VSANStoragePolicyName -Description 'This policy is created by using hostFailuresToTolerate capability' -AnyOfRuleSets $fttRuleSet -Server $vc
            Set-SpbmEntityConfiguration -Configuration (Get-SpbmEntityConfiguration $datastore -Server $vc) -StoragePolicy $fttVsanPolicy | Out-File -Append -LiteralPath $verboseLogFile
            
            My-Logger "Associate $VSANStoragePolicyName with $VCSAName ..."
            $vmhds = Get-VM -Name $VCSAName -Server $vc | Get-HardDisk -WarningAction SilentlyContinue
            Set-SpbmEntityConfiguration -Configuration (Get-SpbmEntityConfiguration $vmhds -Server $vc ) -StoragePolicy $fttVsanPolicy | Out-File -Append -LiteralPath $verboseLogFile
        }
    }

    if($configureVDS -eq 1) {
        if(!($vc = Connect-VIServer $VCSAIP -User $VCSASSOUserName -Password $VCSASSOPassword -WarningAction SilentlyContinue)) {
            Write-Host -ForegroundColor Red "Unable to connect to new VCSA, please check the deployment"
            exit
        } else {
            My-Logger "Successfully logged into new VCSA $vc ..."
        }

        # vmnic0 = Management on VSS -> Futur Management on VDS (uplink2)
        # vmnic1 = Management on VDS (uplink1)
        # vmnic2 = unused
        # vmnic3 = unused

        $vds = Get-VDSwitch $VCSAVDS -Server $vc -ErrorAction Ignore
        if( -not $vds) {
            My-Logger "Creating VDS $VCSAVDS ..."
            $vds = New-VDSwitch -Name $VCSAVDS -Server $vc -Location (Get-Datacenter -Name $VCSADatacenterName -Server $vc) -Mtu $VCSAVDSMTU -NumUplinkPorts 2
        }

		$pmgmt = Get-VDPortgroup $VCSAMgmtPortgroupName -Server $vc -VDSwitch $vds -ErrorAction Ignore
		if( -Not $pmgmt) {
            My-Logger "Creating VDS Management Network Portgroup"
            New-VDPortgroup -Name $VCSAMgmtPortgroupName -Server $vc -Vds $vds -VLanId $vmk0MgmtVLanId | Out-File -Append -LiteralPath $verboseLogFile
		}

		$pvm = Get-VDPortgroup $VCSAVMNetworkPortgroupName -Server $vc -VDSwitch $vds -ErrorAction Ignore
		if( -Not $pvm) {
            My-Logger "Creating VDS VM Network Portgroup"
            New-VDPortgroup -Name $VCSAVMNetworkPortgroupName -Server $vc -Vds $vds -VLanId $NestedVMNetworkVLanId | Out-File -Append -LiteralPath $verboseLogFile
		}

		$pvsan = Get-VDPortgroup $VCSAVSanPortgroupName -Server $vc -VDSwitch $vds -ErrorAction Ignore
		if( -Not $pvsan) {
            My-Logger "Creating VDS VSAN Portgroup"
            New-VDPortgroup -Name $VCSAVSanPortgroupName -Server $vc -Vds $vds -VLanId $vsanVlanId | Out-File -Append -LiteralPath $verboseLogFile
		}
        
        foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
            My-Logger "Adding $vmhost to $VCSAVDS ..."
            $vds | Add-VDSwitchVMHost -VMHost $vmhost -Server $vc| Out-Null

            $vmhostNetworkAdapter1 = Get-VMHost $vmhost -Server $vc| Get-VMHostNetworkAdapter -Physical -Name vmnic1
            $vds | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter1 -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile #add vmnic1 to $VCSAVDS as uplink1
        }

        if($migrateVMstoVDS -eq 1) {
            $dvPortGroup = Get-VDPortgroup -Name $VCSAVMNetworkPortgroupName -Server $vc 

            My-Logger "Reconfiguring VMs to Distributed Portgroup ..."
            Get-VM -Name $VCSAName -Server $vc | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $dvPortGroup -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }
        
        if($migrateVmkernelToVDS -eq 1) {
            $dvportgroupmgmt = Get-VDPortgroup -name $VCSAMgmtPortgroupName -Server $vc

            My-Logger "Migrating VMkernel network to VDS ..."
            foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
                $vmk = Get-VMHostNetworkAdapter -Name vmk0 -Server $vc -VMHost $vmhost
                Set-VMHostNetworkAdapter -PortGroup $dvportgroupmgmt -VirtualNic $vmk -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
                Get-VMHostNetworkAdapter -Name vmk0 -Server $vc -VMHost $vmhost | Set-VMHostNetworkAdapter -Mtu 1500 -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
                $vmhostNetworkAdapter0 = Get-VMHost $vmhost -Server $vc| Get-VMHostNetworkAdapter -Physical -Name vmnic0
                $vds | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter0 -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile #add vmnic0 to $VCSAVDS as uplink2
                Get-VMHostNetworkAdapter -Name vmk0 -Server $vc -VMHost $vmhost | Set-VMHostNetworkAdapter -VMotionEnabled $true -ProvisioningEnabled $true -VsanTrafficEnabled $false -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            }
        }

        # Add VSAN VMkernel Adapter and enable the service on the interface
        $s = 1
        foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
            $esxivSANNetwork = $NestedESXivSANNetworkCidr.split("/")[0]
            $esxivSANNetworkOctects = $esxivSANNetwork.split(".")
            $esxivSANStart = ($esxivSANNetworkOctects[0..2] -join '.') + ".10"
            New-VMHostNetworkAdapter -Server $vc -VMHost $vmhost -PortGroup $VCSAVSanPortgroupName -VirtualSwitch $VCSAVDS -IP "$esxivSANStart$s" -SubnetMask "255.255.255.0" -VsanTrafficEnabled $true | Out-File -Append -LiteralPath $verboseLogFile 
            Get-VMHost $vmhost -Server $vc | Get-VDPortGroup -Name $VCSAVSanPortgroupName | Get-VMHostNetworkAdapter | Set-VMHostNetworkAdapter  -Mtu $VCSAVDSMTU | Out-File -Append -LiteralPath $verboseLogFile
            $s++
        }

        My-Logger "Set vmnic0 uplink2 active and vmnic1 uplink1 unused for $VCSAMgmtPortgroupName and $VCSAVMNetworkPortgroupName"
        Get-VDPortgroup $VCSAMgmtPortgroupName -Server $vc| Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort @("dvUplink2") -UnusedUplinkPort @("dvUplink1") | Out-File -Append -LiteralPath $verboseLogFile
        Get-VDPortgroup $VCSAVMNetworkPortgroupName -Server $vc| Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort @("dvUplink2") -UnusedUplinkPort @("dvUplink1") | Out-File -Append -LiteralPath $verboseLogFile

        if($removeVSS -eq 1) {
            My-Logger "Removing VSS from ESXi hosts ..."
            foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
                $vswitch = Get-VirtualSwitch -Name vSwitch0 -Server $vc -VMHost $vmhost

                Remove-VirtualSwitch -VirtualSwitch $vswitch -Server $vc -confirm:$false
            }
        }
    }

    if($finalCleanUp -eq 1) {
        if(!($vc = Connect-VIServer $VCSAIP -User $VCSASSOUserName -Password $VCSASSOPassword -WarningAction SilentlyContinue)) {
            Write-Host -ForegroundColor Red "Unable to connect to new VCSA, please check the deployment"
            exit
        } else {
            My-Logger "Successfully logged into new VCSA $vc ..."
        }

        My-Logger "Clearing default VSAN Health Check Alarms, not applicable in Nested ESXi env ..."
        $alarmMgr = Get-View AlarmManager -Server $vc
        Get-Cluster -Server $vc | Where-Object {$_.ExtensionData.TriggeredAlarmState} | %{
            $cluster = $_
            $Cluster.ExtensionData.TriggeredAlarmState | %{
                $alarmMgr.AcknowledgeAlarm($_.Alarm,$cluster.ExtensionData.MoRef)
            }
        }
        $alarmSpec = New-Object VMware.Vim.AlarmFilterSpec
        $alarmMgr.ClearTriggeredAlarms($alarmSpec)

        # Final configure and then exit maintanence mode in case patching was done earlier
        foreach ($vmhost in Get-Cluster -Server $vc | Get-VMHost) {
            # Disable Core Dump Warning
            Get-AdvancedSetting -Entity $vmhost -Name UserVars.SuppressCoredumpWarning | Set-AdvancedSetting -Value 1 -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

            if($vmhost.ConnectionState -eq "Maintenance") {
                Set-VMHost -VMhost $vmhost -State Connected -RunAsync -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            }
        }
		
		My-Logger "VCF 9 Import Guardrail tick in vCenter vLCM UI (Migrate powered off and suspended VMs to other hosts in the cluster, if a host must enter maintenance mode)"
		$EsxSettingsDefaultsClustersPoliciesApplyConfiguredPolicySpec = Initialize-EsxSettingsDefaultsClustersPoliciesApplyConfiguredPolicySpec -EvacuateOfflineVms $true
		Invoke-SetDefaultsClustersPoliciesApply -esxSettingsDefaultsClustersPoliciesApplyConfiguredPolicySpec $esxSettingsDefaultsClustersPoliciesApplyConfiguredPolicySpec -ErrorAction Ignore -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
		Start-Sleep -Seconds 30
	
        Get-Cluster $VCSAClusterName -Server $vc -ErrorAction Ignore | Set-Cluster -DrsAutomationLevel FullyAutomated -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
		Start-Sleep -Seconds 30
    }
}

if( $NSXuseExistingDeploymentNSX -eq 1) {
    if($deployNSXManager -eq 1) {
        if(!($vc = Connect-VIServer $VCSAIP -User $VCSASSOUserName -Password $VCSASSOPassword -WarningAction SilentlyContinue)) {
            Write-Host -ForegroundColor Red "Unable to connect to new VCSA, please check the deployment"
            exit
        } else {
            My-Logger "Successfully logged into new VCSA $vc ..."
        }
		$cluster = Get-Cluster $VCSAClusterName -Server $vc 
		$datastore = Get-Datastore -Name $VSANDatastoreName -Server $vc | Select-Object -First 1
		$vmhost = $cluster | Get-VMHost | Select -First 1
		
        $NSXManagerHostnameToIPsForManagementDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
            $VMName = $_.Key
            $VMIPAddress = $_.Value

            # Deploy NSX Manager
            $nsxMgrOvfConfig = Get-OvfConfiguration $NSXTManagerOVA
            $nsxMgrOvfConfig.DeploymentOption.Value = $NSXManagerSize
            $nsxMgrOvfConfig.NetworkMapping.Network_1.value = $VCSAVMNetworkPortgroupName

            $nsxMgrOvfConfig.Common.nsx_role.Value = "NSX Manager"
            $nsxMgrOvfConfig.Common.nsx_hostname.Value = "${VMName}.${VMDomain}"
            $nsxMgrOvfConfig.Common.nsx_ip_0.Value = $VMIPAddress
            $nsxMgrOvfConfig.Common.nsx_netmask_0.Value = $VMNetmask
            $nsxMgrOvfConfig.Common.nsx_gateway_0.Value = $VMGateway
            $nsxMgrOvfConfig.Common.nsx_dns1_0.Value = $VMDNS
            $nsxMgrOvfConfig.Common.nsx_domain_0.Value = $VMDomain
            $nsxMgrOvfConfig.Common.nsx_ntp_0.Value = $VMNTP

            if($NSXSSHEnable -eq "true") {
                $NSXSSHEnableVar = $true
            } else {
                $NSXSSHEnableVar = $false
            }
            $nsxMgrOvfConfig.Common.nsx_isSSHEnabled.Value = $NSXSSHEnableVar
            if($NSXEnableRootLogin -eq "true") {
                $NSXRootPasswordVar = $true
            } else {
                $NSXRootPasswordVar = $false
            }
            $nsxMgrOvfConfig.Common.nsx_allowSSHRootLogin.Value = $NSXRootPasswordVar

            $nsxMgrOvfConfig.Common.nsx_passwd_0.Value = $NSXRootPassword
            $nsxMgrOvfConfig.Common.nsx_cli_username.Value = $NSXAdminUsername
            $nsxMgrOvfConfig.Common.nsx_cli_passwd_0.Value = $NSXAdminPassword
            $nsxMgrOvfConfig.Common.nsx_cli_audit_username.Value = $NSXAuditUsername
            $nsxMgrOvfConfig.Common.nsx_cli_audit_passwd_0.Value = $NSXAuditPassword

            My-Logger "Deploying NSX Manager VM $VMName ..."
            $nsxmgr_vm = Import-VApp -Source $NSXTManagerOVA -OvfConfiguration $nsxMgrOvfConfig -Name $VMName -Location $cluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin -Force

            My-Logger "Updating vCPU Count to $NSXTMgrvCPU & vMEM to $NSXTMgrvMEM GB and Disabling Reservations ..."
            Set-VM -Server $vc -VM $nsxmgr_vm -NumCpu $NSXTMgrvCPU -MemoryGB $NSXTMgrvMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

            Get-VM -Server $vc -Name $nsxmgr_vm | Get-VMResourceConfiguration | Set-VMResourceConfiguration -CpuReservationMhz 0 | Out-File -Append -LiteralPath $verboseLogFile
            
            Get-VM -Server $vc -Name $nsxmgr_vm | Get-VMResourceConfiguration | Set-VMResourceConfiguration -MemReservationGB 0 | Out-File -Append -LiteralPath $verboseLogFile    
            
            My-Logger "Allow the guest operating system to retrieve entropy directly from the ESXi host and Powering On $nsxmgr_vm ..."
            Get-VM -Server $vc -Name $nsxmgr_vm | New-AdvancedSetting -Name "isolation.tools.getEntropy.disable" -value "FALSE" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

            $nsxmgr_vm | Start-Vm -RunAsync | Out-Null
        }
    }

    if($postDeployNSXConfig -eq 1) {
        # First boot took 24min so be patient ..."
        $NSXManagerNode1IP = $($NSXManagerHostnameToIPsForManagementDomain.Values|Sort-Object) | Select-Object -Index 0
		
        do {
            My-Logger "waiting 12min ..."
            $ping = Test-Connection $NSXManagerNode1IP -Delay 240 -Quiet
        } until ($ping -contains "True")
		
        My-Logger "Connecting to NSX Manager for post-deployment configuration ..."
		$NSXManagerNode1Hostname = ($($NSXManagerHostnameToIPsForManagementDomain.Keys|Sort-Object) | Select-Object -Index 0) + ".${VMDomain}"
        if(!(Connect-NsxtServer -Server $NSXManagerNode1Hostname -Username $NSXAdminUsername -Password $NSXAdminPassword -WarningAction SilentlyContinue)) {
            Write-Host -ForegroundColor Red "Unable to connect to NSX-T Manager, please check the deployment"
            exit
        } else {
            My-Logger "Successfully logged into NSX-T Manager $NSXManagerNode1Hostname  ..."
        }

        $runHealth=$true
        $runCEIP=$true
		$runSetNSXVIP=$true
		$runNSXCluster=$true
        $runAddVC=$true

        if($runHealth) {
            My-Logger "Verifying health of all NSX Manager/Controller Nodes ..."
            $clusterNodeService = Get-NsxtService -Name "com.vmware.nsx.cluster.nodes"
            $clusterNodeStatusService = Get-NsxtService -Name "com.vmware.nsx.cluster.nodes.status"
            $nodes = $clusterNodeService.list().results
            $mgmtNodes = $nodes | where { $_.controller_role -eq $null }
            $controllerNodes = $nodes | where { $_.manager_role -eq $null }

            foreach ($mgmtNode in $mgmtNodes) {
                $mgmtNodeId = $mgmtNode.id
                $mgmtNodeName = $mgmtNode.appliance_mgmt_listen_addr

                if($debug) { My-Logger "Check health status of Mgmt Node $mgmtNodeName ..." }
                while ( $clusterNodeStatusService.get($mgmtNodeId).mgmt_cluster_status.mgmt_cluster_status -ne "CONNECTED") {
                    if($debug) { My-Logger "$mgmtNodeName is not ready, sleeping 20 seconds ..." }
                    Start-Sleep 20
                }
            }

            foreach ($controllerNode in $controllerNodes) {
                $controllerNodeId = $controllerNode.id
                $controllerNodeName = $controllerNode.controller_role.control_plane_listen_addr.ip_address

                if($debug) { My-Logger "Checking health of Ctrl Node $controllerNodeName ..." }
                while ( $clusterNodeStatusService.get($controllerNodeId).control_cluster_status.control_cluster_status -ne "CONNECTED") {
                    if($debug) { My-Logger "$controllerNodeName is not ready, sleeping 20 seconds ..." }
                    Start-Sleep 20
                }
            }
        }

        if($runCEIP) {
            My-Logger "Accepting CEIP Agreement ..."
            $ceipAgreementService = Get-NsxtService -Name "com.vmware.nsx.telemetry.agreement"
            $ceipAgreementSpec = $ceipAgreementService.get()
            $ceipAgreementSpec.telemetry_agreement_displayed = $true
            $agreementResult = $ceipAgreementService.update($ceipAgreementSpec)
        }
		
		if($runSetNSXVIP) {
			My-Logger "Set NSX Managers Cluster Virtual IP via API"
            $NSXManagerNode1Hostname = ($($NSXManagerHostnameToIPsForManagementDomain.Keys|Sort-Object) | Select-Object -Index 0) + ".${VMDomain}"
			$pair = "${NSXAdminUsername}:${NSXAdminPassword}"
			$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
			$base64 = [System.Convert]::ToBase64String($bytes)

			$headers = @{
				"Authorization"="basic $base64"
				"Content-Type"="application/json"
				"Accept"="application/json"
			}

			$nsxVipUrl = "https://$NSXManagerNode1Hostname/api/v1/cluster/api-virtual-ip?action=set_virtual_ip&ip_address=$NSXManagerVIPIP&force=true"
			$requests = Invoke-WebRequest -Uri $nsxVipUrl -Method POST -Headers $headers -SkipCertificateCheck
		}
		
		Start-Sleep 30
		
		if($runNSXCluster) {
			if ($NSXManagerHostnameToIPsForManagementDomain.count -eq 3) {
				$NSXManagerNode1IP = $($NSXManagerHostnameToIPsForManagementDomain.Values|Sort-Object) | Select-Object -Index 0
				$NSXManagerNode2IP = $($NSXManagerHostnameToIPsForManagementDomain.Values|Sort-Object) | Select-Object -Index 1
				$NSXManagerNode3IP = $($NSXManagerHostnameToIPsForManagementDomain.Values|Sort-Object) | Select-Object -Index 2
				$clusterService = Get-NsxtService -Name "com.vmware.nsx.cluster"
				$clusterId = $clusterService.get().cluster_id
				$clusterNodesApiThumbprint = $clusterService.get().nodes.api_listen_addr.certificate_sha256_thumbprint

				$json = [pscustomobject] @{
					"cluster_id" = $clusterId
					"ip_address" = $NSXManagerNode1IP
					"username" = $NSXAdminUsername
					"password" = $NSXAdminPassword
					"certificate_sha256_thumbprint" = $clusterNodesApiThumbprint
				}

				$body = $json | ConvertTo-Json -Depth 10

				$pair = "${NSXAdminUsername}:${NSXAdminPassword}"
				$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
				$base64 = [System.Convert]::ToBase64String($bytes)

				$headers = @{
					"Authorization"="basic $base64"
					"Content-Type"="application/json"
					"Accept"="application/json"
				}

				$nodes = @($NSXManagerNode2IP, $NSXManagerNode3IP)

				foreach ($node in $nodes) {

					$joinclusterUrl = "https://$node/api/v1/cluster?action=join_cluster"


					if($debug) {
						"URL: $joinclusterUrl" | Out-File -Append -LiteralPath $verboseLogFile
						"Headers: $($headers | Out-String)" | Out-File -Append -LiteralPath $verboseLogFile
						"Body: $body" | Out-File -Append -LiteralPath $verboseLogFile
					}

					try {
						My-Logger "$node Join NSX Manager Cluster  ..."
						if($PSVersionTable.PSEdition -eq "Core") {
							$requests = Invoke-WebRequest -Uri $joinclusterUrl -Body $body -Method POST -Headers $headers -SkipCertificateCheck
							Start-Sleep 20
						} else {
							$requests = Invoke-WebRequest -Uri $joinclusterUrl -Body $body -Method POST -Headers $headers
							Start-Sleep 20
						}
					} catch {
						Write-Error "Error in joining NSX Manager Cluster"
						Write-Error "`n($_.Exception.Message)`n"
						break
					}
					
					if($requests.StatusCode -eq 200) {
						My-Logger "Successfully joined $node to NSX Manager Cluster"
					} else {
						My-Logger "Unknown State: "
						$requests | Out-File -Append -LiteralPath $verboseLogFile
						}
				}
			}
		}
		
		Start-Sleep 20

        if($runAddVC) {
            $vcsaFQDN = $VCSAName + "." + $VMDomain
            My-Logger "Adding vCenter Server Compute Manager ..."
            $computeManagerService = Get-NsxtService -Name "com.vmware.nsx.fabric.compute_managers"
            $computeManagerStatusService = Get-NsxtService -Name "com.vmware.nsx.fabric.compute_managers.status"

            $computeManagerSpec = $computeManagerService.help.create.compute_manager.Create()
            $credentialSpec = $computeManagerService.help.create.compute_manager.credential.username_password_login_credential.Create()
            $VCUsername = $VCSASSOUserName
            $VCURL = "https://" + $vcsaFQDN + ":443"
            $VCThumbprint = Get-SSLThumbprint256 -URL $VCURL
            $credentialSpec.username = $VCUsername
            $credentialSpec.password = $VCSASSOPassword
            $credentialSpec.thumbprint = $VCThumbprint
            $computeManagerSpec.server = $vcsaFQDN
            $computeManagerSpec.origin_type = "vCenter"
            $computeManagerSpec.display_name = $VCSAName
            $computeManagerSpec.credential = $credentialSpec
            $computeManagerSpec.create_service_account = $true
            $computeManagerSpec.set_as_oidc_provider = $true
            $computeManagerResult = $computeManagerService.create($computeManagerSpec)

            if($debug) { My-Logger "Waiting for VC registration to complete ..." }
                while ( $computeManagerStatusService.get($computeManagerResult.id).registration_status -ne "REGISTERED") {
                    if($debug) { My-Logger "$vcsaFQDN is not ready, sleeping 30 seconds ..." }
                    Start-Sleep 30
            }
        }

        My-Logger "Disconnecting from NSX Manager ..."
        Disconnect-NsxtServer -Confirm:$false
    }
}

if($moveVMsIntovApp -eq 1) {
    My-Logger "Connecting to Management vCenter Server $VIServer ..."
    $viConnection = Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue
	$WarningPreference = 'SilentlyContinue'
	if($deployVCFInstaller -eq 1 -or $deployNestedESXiVMsForMgmt -eq 1) {
		$datastore = Get-Datastore -Server $viConnection -Name $VMDatastoreMGMT | Select-Object -First 1
	} else {
		$datastore = Get-Datastore -Server $viConnection -Name $VMDatastoreWLD | Select-Object -First 1
	}
    $cluster = Get-Cluster -Server $viConnection -Name $VMCluster
    $vmhost = $cluster | Get-VMHost -Datastore $datastore
    # Check whether DRS is enabled as that is required to create vApp
    if((Get-Cluster -Server $viConnection $cluster).DrsEnabled) {
		if(-Not (Get-VApp -Name $VAppName -ErrorAction Ignore)) {
			My-Logger "Creating vApp $VAppName ..."
			$rp = Get-ResourcePool -Name Resources -Location $cluster
			$VApp = New-VApp -Name $VAppName -Server $viConnection -Location $cluster
		} else {
				$VApp = $VAppName
		}

        if(-Not (Get-Folder $VMFolder -ErrorAction Ignore)) {
            My-Logger "Creating VM Folder $VMFolder ..."
            $folder = New-Folder -Name $VMFolder -Server $viConnection -Location (Get-Datacenter $VMDatacenter -Server $viConnection | Get-Folder vm)
        }
		
        if($deployVCFInstaller -eq 1) {
            $vcfInstallerVM = Get-VM -Name $VCFInstallerVMName -Server $viConnection -Location $cluster | Where-Object {$_.ResourcePool.Id -eq $rp.Id}
            My-Logger "Moving $VCFInstallerVMName into $VAppName vApp ..."
            Move-VM -VM $vcfInstallerVM -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }

        if($deployNestedESXiVMsForMgmt -eq 1) {
            My-Logger "Moving Nested Managenment ESXi VMs into $VAppName vApp ..."
            $NestedESXiHostnameToIPsForManagementDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
                $vm = Get-VM -Name $_.Key -Server $viConnection -Location $cluster | Where-Object {$_.ResourcePool.Id -eq $rp.Id}
                Move-VM -VM $vm -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            }
        }

        if($deployNestedESXiVMsForWLD -eq 1) {
            My-Logger "Moving Nested Workload ESXi VMs into $VAppName vApp ..."
			$WarningPreference = 'SilentlyContinue'
            $NestedESXiHostnameToIPsForWorkloadDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
                $vm = Get-VM -Name $_.Key -Server $viConnection -Location $cluster | Where-Object {$_.ResourcePool.Id -eq $rp.Id}
                Move-VM -VM $vm -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            }
        }

        My-Logger "Moving $VAppName to VM Folder $VMFolder ..."
        Move-VApp -Server $viConnection $VAppName -Destination (Get-Folder -Server $viConnection $VMFolder) | Out-File -Append -LiteralPath $verboseLogFile
    } else {
        My-Logger "vApp $VAppName will NOT be created as DRS is NOT enabled on vSphere Cluster ${cluster} ..."
    }
}


if($generateMgmtJson -eq 1) {
    $vcsaFQDN = $VCSAName + "." + $VMDomain
	$NSXManagerNode1IP = $($NSXManagerHostnameToIPsForManagementDomain.Values|Sort-Object) | Select-Object -Index 0
	$NSXManagerNode1Hostname = ($($NSXManagerHostnameToIPsForManagementDomain.Keys|Sort-Object) | Select-Object -Index 0) + ".${VMDomain}"
	$NSXManagerNode2Hostname = ($($NSXManagerHostnameToIPsForManagementDomain.Keys|Sort-Object) | Select-Object -Index 1) + ".${VMDomain}"
	$NSXManagerNode3Hostname = ($($NSXManagerHostnameToIPsForManagementDomain.Keys|Sort-Object) | Select-Object -Index 2) + ".${VMDomain}"	
    # For Convert existing vCenter a guardrails requires VMKernel ESX Management to be vMotion Enabled, below 'if' for switching to management network CIDR variable and gateway.
    if( $VCSAuseExistingDeploymentvCenter -eq 1) {
        $vcsaThumbprint = (Get-SSLThumbprint256 -URL https://${VCSAIP})
        $vcsaUseExisting = $true
        $esxivMotionNetwork = $NestedESXiManagementNetworkCidr.split("/")[0]
        $esxivMotionNetworkOctects = $esxivMotionNetwork.split(".")
        $esxivMotionGateway = ($esxivMotionNetworkOctects[0..2] -join '.') + ".${VMNestedESXiMgmtGateway}"
        $esxivMotionStart = ($esxivMotionNetworkOctects[0..2] -join '.') + ".101"
        $esxivMotionEnd = ($esxivMotionNetworkOctects[0..2] -join '.') + ".116"
    } else {
        $vcsaThumbprint = $null
        $vcsaUseExisting = $null
        $esxivMotionNetwork = $NestedESXivMotionNetworkCidr.split("/")[0]
        $esxivMotionNetworkOctects = $esxivMotionNetwork.split(".")
        $esxivMotionGateway = ($esxivMotionNetworkOctects[0..2] -join '.') + ".1"
        $esxivMotionStart = ($esxivMotionNetworkOctects[0..2] -join '.') + ".101"
        $esxivMotionEnd = ($esxivMotionNetworkOctects[0..2] -join '.') + ".116"
    }
    
    if( $NSXuseExistingDeploymentNSX -eq 1) {
        $nsxUseExisting = $true
		$nsxThumbprint = (Get-SSLThumbprint256 -URL https://${NSXManagerNode1IP})
    } else {
        $nsxUseExisting = $null
    }

    $esxivSANNetwork = $NestedESXivSANNetworkCidr.split("/")[0]
    $esxivSANNetworkOctects = $esxivSANNetwork.split(".")
    $esxivSANGateway = ($esxivSANNetworkOctects[0..2] -join '.') + ".1"
    $esxivSANStart = ($esxivSANNetworkOctects[0..2] -join '.') + ".101"
    $esxivSANEnd = ($esxivSANNetworkOctects[0..2] -join '.') + ".116"

    $esxiNSXTepNetwork = $NestedESXiNSXTepNetworkCidr.split("/")[0]
    $esxiNSXTepNetworkOctects = $esxiNSXTepNetwork.split(".")
    $esxiNSXTepGateway = ($esxiNSXTepNetworkOctects[0..2] -join '.') + ".1"
    $esxiNSXTepStart = ($esxiNSXTepNetworkOctects[0..2] -join '.') + ".101"
    $esxiNSXTepEnd = ($esxiNSXTepNetworkOctects[0..2] -join '.') + ".132"

    $hostSpecs = @()
    $count = 1
    $NestedESXiHostnameToIPsForManagementDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $VMName = $_.Key

        $hostSpec = [ordered]@{
            "hostname" = $VMName
            "credentials" = [ordered]@{
                "username" = "root"
                "password" = $VMPassword
            }
        }
        $hostSpecs+=$hostSpec
        $count++
    }

    $vcfConfig = [ordered]@{
        "sddcId" = $DeploymentId
        "vcfInstanceName" = $DeploymentInstanceName
        "workflowType" = $VCFInstallerProductSKU
        "version" = $VCFInstallerProductVersion
        "ceipEnabled" = $CEIPEnabled
        "fipsEnabled" = $FIPSEnabled
        "skipEsxThumbprintValidation" = $true
        "skipGatewayPingValidation" = $true
    }

    if($VCFInstallerProductSKU -eq "VCF"){
        $sddcmSpec = [ordered]@{
            "rootUserCredentials" = [ordered]@{
                "username" = "root"
                "password" = $SddcManagerRootPassword
            }
            "secondUserCredentials" = [ordered]@{
                "username" = "vcf"
                "password" = $SddcManagerVcfPassword
            }
            "hostname" = $SddcManagerHostname
            "useExistingDeployment" = $false
            "rootPassword" = $SddcManagerRootPassword
            "sshPassword" = $SddcManagerSSHPassword
            "localUserPassword" = $SddcManagerLocalPassword
        }
        $vcfConfig.Add("sddcManagerSpec",$sddcmSpec)
    }

        $dnsSpec = [ordered]@{
            "nameservers" = @($VMDNS)
            "subdomain" = $VMDomain
        }
        $ntpSpec = @($VMNTP)
        $vcSpec = [ordered]@{
            "vcenterHostname" = $vcsaFQDN
            "rootVcenterPassword" = $VCSARootPassword
            "vmSize" = $VCSASize
            "storageSize" = ""
            "adminUserSsoUsername" = $VCSASSOUserName
            "adminUserSsoPassword" = $VCSASSOPassword
            "ssoDomain" = $VCSASSODomainName
            "sslThumbprint" = $vcsaThumbprint
            "useExistingDeployment" = $vcsaUseExisting
        }
        $hostSpec = $hostSpecs
        $clusterSpec = [ordered]@{
            "clusterName" = $VCSAClusterName
            "datacenterName" = $VCSADatacenterName
            "clusterEvcMode" = $VCSAclusterEvcMode
        }
        $dsSpec = [ordered]@{
            "vsanSpec" = [ordered] @{
                "failuresToTolerate" = $VSANFTT
                "vsanDedup" = $VSANDedupe
                "esaConfig" = @{
                    "enabled" = $VSANESAEnabled
                }
                "datastoreName" = $VSANDatastoreName
            }
        }
        $vcfConfig.Add("dnsSpec",$dnsSpec)
        $vcfConfig.Add("ntpServers",$ntpSpec)
        $vcfConfig.Add("vcenterSpec",$vcSpec)
        $vcfConfig.Add("hostSpecs",$hostSpec)
        $vcfConfig.Add("clusterSpec",$clusterSpec)
        $vcfConfig.Add("datastoreSpec",$dsSpec)

    if($VCFInstallerProductSKU -eq "VCF"){
        $nsxSpec = [ordered]@{
            "nsxtManagerSize" = $NSXManagerSize
            "nsxtManagers" = @(
                @{
					"hostname" = $NSXManagerNode1Hostname
				}
                if($NSXManagerHostnameToIPsForManagementDomain.count -eq 3){
                    @{
                        "hostname" = $NSXManagerNode2Hostname
                    }
                    @{
                        "hostname" = $NSXManagerNode3Hostname
                    }
                }
            )
            "vipFqdn" = $NSXManagerVIPHostname
            "useExistingDeployment" = $nsxUseExisting
			"sslThumbprint" = $nsxThumbprint
            "nsxtAdminPassword" = $NSXAdminPassword
            "nsxtAuditPassword" = $NSXAuditPassword
            "rootNsxtManagerPassword" = $NSXRootPassword
            "skipNsxOverlayOverManagementNetwork" = $true
            "ipAddressPoolSpec" = [ordered]@{
                "name" = "tep01"
                "description" = "ESXi Host Overlay TEP IP Pool"
                "subnets" = @(
                    @{
                        "cidr" = $NestedESXiNSXTepNetworkCidr
                        "gateway" = $esxiNSXTepGateway
                        "ipAddressPoolRanges" = @(@{"start" = $esxiNSXTepStart;"end" = $esxiNSXTepEnd})
                    }
                )
            }
            "transportVlanId" = $esxiNSXTepVlanId
        }

        $vcfConfig.Add("nsxtSpec",$nsxSpec)
    }

        $opsSpec = [ordered]@{
            "nodes" = @(
                @{
                    "hostname" = $VCFOperationsHostname
                    "rootUserPassword" = $VCFOperationsRootPassword
                    "type" = "master"
                }
            )
            "adminUserPassword" = $VCFOperationsAdminPassword
            "applianceSize" = $VCFOperationsSize
            "useExistingDeployment" = $false
            "loadBalancerFqdn" = ""
        }
        $vcfConfig.Add("vcfOperationsSpec",$opsSpec)

    if($VCFInstallerProductSKU -eq "VCF") {
        $opsFleetSpec = [ordered]@{
            "hostname" = $VCFOperationsFleetManagerHostname
            "rootUserPassword" = $VCFOperationsFleetManagerRootPassword
            "adminUserPassword" = $VCFOperationsFleetManagerAdminPassword
            "useExistingDeployment" = $false
        }
        $opsCollectorSpec = [ordered]@{
            "hostname" = $VCFOperationsCollectorHostname
            "applicationSize" = $VCFOperationsCollectorSize
            "rootUserPassword" = $VCFOperationsCollectorRootPassword
            "useExistingDeployment" = $false
        }
        if($noVCFAutomation -eq 1) {
            $autoSpec = $null
        } else {
            $autoSpec = [ordered]@{
                "hostname" = $VCFAutomationHostname
                "adminUserPassword" = $VCFAutomationAdminPassword
                "ipPool" = $VCFAutomationIPPool
                "nodePrefix" = $VCFAutomationNodePrefix
                "internalClusterCidr" = $VCFAutomationClusterCIDR
                "useExistingDeployment" = $false
                }
        }
    }
        $netSpec = @(
            [ordered]@{
                "networkType" = "MANAGEMENT"
                "subnet" = $NestedESXiManagementNetworkCidr
                "gateway" = $VMNestedESXiMgmtGateway
                "subnetMask" = $null
                "includeIpAddress" = $null
                "includeIpAddressRanges" = $null
                "vlanId" = "$vmk0MgmtVLanId"
                "mtu" = "1500"
                "teamingPolicy" = "loadbalance_loadbased"
                "activeUplinks" = @("uplink1","uplink2")
                "standbyUplinks" = @()
                "portGroupKey" = "DVPG_FOR_MANAGEMENT"
            }
            [ordered]@{
                "networkType" = "VM_MANAGEMENT"
                "subnet" = $NestedVmManagementNetworkCidr
                "gateway" = $VMGateway
                "subnetMask" = $null
                "includeIpAddress" = $null
                "includeIpAddressRanges" = $null
                "vlanId" = "$NestedVMNetworkVLanId"
                "mtu" = "1500"
                "teamingPolicy" = "loadbalance_loadbased"
                "activeUplinks" = @("uplink1","uplink2")
                "standbyUplinks" = @()
                "portGroupKey" = "DVPG_FOR_VM_MANAGEMENT"
            }
            [ordered]@{
                "networkType" = "VMOTION"
                "subnet" = $NestedESXivMotionNetworkCidr
                "gateway" = $esxivMotionGateway
                "subnetMask" = $null
                "includeIpAddress" = $null
                "includeIpAddressRanges" = @(@{"startIpAddress" = $esxivMotionStart;"endIpAddress" = $esxivMotionEnd})
                "vlanId" = "$vmotionVlanId"
                "mtu" = "9000"
                "teamingPolicy" = "loadbalance_loadbased"
                "activeUplinks" = @("uplink1","uplink2")
                "standbyUplinks" = @()
                "portGroupKey" = "DVPG_FOR_VMOTION"
            }
            [ordered]@{
                "networkType" = "VSAN"
                "subnet" = $NestedESXivSANNetworkCidr
                "gateway"= $esxivSANGateway
                "subnetMask" = $null
                "includeIpAddress" = $null
                "teamingPolicy" = "loadbalance_loadbased"
                "includeIpAddressRanges" = @(@{"startIpAddress" = $esxivSANStart;"endIpAddress" = $esxivSANEnd})
                "vlanId" = "$vsanVlanId"
                "mtu" = "9000"
                "activeUplinks" = @("uplink1","uplink2")
                "standbyUplinks" = @()
                "portGroupKey" = "DVPG_FOR_VSAN"
            }
        )
        $vdsSpec = @(
            [ordered]@{
                "dvsName" = "sddc1-cl01-vds01"
                "networks" = @(
                    "MANAGEMENT",
                    "VM_MANAGEMENT",
                    "VMOTION",
                    "VSAN"
                )
                "mtu" = "9000"
                "nsxtSwitchConfig" = [ordered]@{
                    "transportZones" = @(
                        @{
                            "transportType" = "OVERLAY"
                            "name" = "VCF-Created-Overlay-Zone"
                        }
                    )
                    "hostSwitchOperationalMode" = "STANDARD"
                }
                "vmnicsToUplinks" = @(
                    @{
                        "id" = "vmnic0"
                        "uplink" = "uplink1"
                    }
                    @{
                        "id" = "vmnic1"
                        "uplink" = "uplink2"
                    }
                )
                "nsxTeamings" = @(
                    @{
                        "policy" = "LOADBALANCE_SRCID"
                        "activeUplinks" = @("uplink1","uplink2")
                        "standByUplinks" = @()
                    }
                )
                "lagSpecs" = $null
                "vmnics" = @("vmnic0","vmnic1")
            }
        )

    if($VCFInstallerProductSKU -eq "VCF") {
        $vcfConfig.Add("vcfOperationsFleetManagementSpec",$opsFleetSpec)
        $vcfConfig.Add("vcfOperationsCollectorSpec",$opsCollectorSpec)
        $vcfConfig.Add("vcfAutomationSpec",$autoSpec)
    }

    $vcfConfig.Add("networkSpecs",$netSpec)
    $vcfConfig.Add("dvsSpecs",$vdsSpec)

    My-Logger "Generating $VCFInstallerProductSKU Management Domain deployment JSON file $VCFManagementDomainJSONFile"
    $vcfConfig | ConvertTo-Json -Depth 20 | Out-File -LiteralPath $VCFManagementDomainJSONFile
}

if($configureVCFInstallerConfig -eq 1) {
    My-Logger "Updating VCF Installer Software Depot ..."

    Verify-VCFAPIEndpoint -EndpointName "VCF Installer" -EndpointIp $VCFInstallerFQDN

    $connectDepot = 1
    $syncDepot = 1
    $downloadReleases = 1

    if($connectDepot -eq 1) {
        Connect-VCFDepot -EndpointIp $VCFInstallerFQDN
    }

    if($syncDepot -eq 1) {
        Sync-VCFDepot -EndpointIp $VCFInstallerFQDN
    }

    if($downloadReleases -eq 1) {
        Download-VCFRelease -EndpointIp $VCFInstallerFQDN
    }
}

if($startVCFBringup -eq 1) {
    My-Logger "Starting $VCFInstallerProductSKU Deployment Bringup ..."

    $headers = Get-VCFInstallerToken

    $printSuccess = 1
    try {
        $uri = "https://${VCFInstallerFQDN}/v1/sddcs"
        $method = "POST"
        $body = Get-Content -Raw $VCFManagementDomainJSONFile

        if($Debug) {
            My-Logger "DEBUG: Method: $method"
            My-Logger "DEBUG: Uri: $uri"
            My-Logger "DEBUG: Body: $body"
        }

        $requests = Invoke-WebRequest -Uri $uri -Method $method -SkipCertificateCheck -TimeoutSec 5 -Headers $headers -Body $body
    }
    catch {
        if($requests.StatusCode -eq 200 -or $requests.StatusCode -eq 202) {
            $printSuccess = 0
            My-Logger "Open browser to the VMware VCF Installer UI (https://${VCFInstallerFQDN}/vcf-installer-ui/portal/progress-viewer) to monitor deployment progress ..."
        } else {
            My-Logger "Failed to submit $VCFInstallerProductSKU Deployment request ..."
            $requests
            exit
        }
    }
    if($printSuccess -eq 1) {
        My-Logger "Open browser to the VMware VCF Installer UI (https://${VCFInstallerFQDN}/vcf-installer-ui/portal/progress-viewer) to monitor deployment progress ..."
    }
}

if($startVCFBringup -eq 1 -and $uploadVCFNotifyScript -eq 1) {
    if(Test-Path $srcNotificationScript) {
        $vcfVM = Get-VM -Server $viConnection $VCFInstallerVMName -Location $VMCluster  | Where-Object {$_.ResourcePool.Id -eq $rp.Id} 

        My-Logger "Uploading VCF notification script $srcNotificationScript to $dstNotificationScript on VCF Installer appliance ..."
        Copy-VMGuestFile -Server $viConnection -VM $vcfVM -Source $srcNotificationScript -Destination $dstNotificationScript -LocalToGuest -GuestUser "root" -GuestPassword $VCFInstallerRootPassword | Out-Null
        Invoke-VMScript -Server $viConnection -VM $vcfVM -ScriptText "chmod +x $dstNotificationScript" -GuestUser "root" -GuestPassword $VCFInstallerRootPassword | Out-Null

        My-Logger "Configuring crontab to run notification check script every 15 minutes ..."
        Invoke-VMScript -Server $viConnection -VM $vcfVM -ScriptText "echo '*/15 * * * * $dstNotificationScript' > /var/spool/cron/root" -GuestUser "root" -GuestPassword $VCFInstallerRootPassword | Out-Null
    }
}

if($VCSAuseExistingDeploymentvCenter -eq 1) {
	if($updateSddcManagerConfig -eq 1) {
		My-Logger "Connecting to the new VCSA ..."
        $vc = Connect-VIServer $VCSAIP -User $VCSASSOUserName -Password $VCSASSOPassword -WarningAction SilentlyContinue
		My-Logger "Waiting for SDDC Manager UI to be ready ..."
		while(1) {
			try {
				$requests = Invoke-WebRequest -Uri "https://${SddcManagerFQDN}/vcf-installer-ui/login" -Method GET -SkipCertificateCheck -TimeoutSec 5
				if($requests.StatusCode -eq 200) {
					My-Logger "`tSDDC Manager UI https://${SddcManagerFQDN}/vcf-installer-ui/login is now ready!"
					break
				}
			}
			catch {
				My-Logger "SDDC Manager UI is not ready yet, sleeping for 120 seconds ..."
				Start-Sleep 120
			}
		}

		$vcfVM = Get-VM -Server $vc $SddcManagerHostname -Location $VCSAClusterName

		$scriptName = "vcfIntScript2.sh"
		$script = @"
#!/bin/bash
# Generated by William Lam's VCF 9 Automated Deployment Lab Script


"@

		if($VCFInstallerSoftwareDepot -eq "offline") {
			$vcfLcmConfigFile = "/opt/vmware/vcf/lcm/lcm-app/conf/application-prod.properties"

			if($VCFInstallerDepotHttps -eq $false) {
				$script += "sed -i -e `"/lcm.depot.adapter.port=.*/a lcm.depot.adapter.httpsEnabled=false`" ${vcfLcmConfigFile}`n"
			}
		}

		if($VCSAuseExistingDeploymentvCenter -eq 1 -and $NestedESXiHostnameToIPsForManagementDomain.count -lt 3) {
			# Remove Guardrail 3 nodes VSAN requirements if count less than 3 ESXi nodes are actively used in the sample (non-actively used hostname/IP can be commented in the array)
			$script += "vsan=""conforming-cluster-present-check""`n"
			$script += "jq --arg vsan `$vsan` 'del(.children[]?.externalValidations[]? | select(.id == `$vsan`))' /opt/vmware/vcf/operationsmanager/scripts/assessment/guardrails/operations/import/import.json >import.tmp && mv import.tmp /opt/vmware/vcf/operationsmanager/scripts/assessment/guardrails/operations/import/import.json`n"
		}
		
		if($VCSAuseExistingDeploymentvCenter -eq 1 -and $NSXuseExistingDeploymentNSX -eq 1 -and $NSXManagerHostnameToIPsForManagementDomain.count -lt 3) {
			# Remove Guardrail 3 nodes NSX requirements if less than 3 NSX nodes are actively used in the sample (non-actively used hostname/IP can be commented)
			$script += "nsx=""import-existing-nsxt-cluster-size""`n"
			$script += "jq --arg nsx `$nsx` 'del(.constraints[]? | select(.id == `$nsx`))' /opt/vmware/vcf/operationsmanager/scripts/assessment/guardrails/common/resourcestates/nsx-import-base.json >nsx-import-base.tmp && mv nsx-import-base.tmp /opt/vmware/vcf/operationsmanager/scripts/assessment/guardrails/common/resourcestates/nsx-import-base.json`n"
		}
        
		$script | Out-File $scriptName

		My-Logger "Transfering configuration shell script ($scriptName) to SDDC Manager VM (in case of reusing the same Lab vApp be aware to set this variable updateSddcManagerConfig = 0) ..."
		Copy-VMGuestFile -Server $viConnection -VM $vcfVM -GuestUser "root" -GuestPassword $SddcManagerRootPassword -LocalToGuest -Source ${scriptName} -Destination /tmp/${scriptName} -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
		My-Logger "Running configuration shell script on SDDC Manager VM ..."
		Invoke-VMScript -ScriptText "bash /tmp/${scriptName}" -VM $vcfVM -GuestUser "root" -GuestPassword $SddcManagerRootPassword | Out-File -Append -LiteralPath $verboseLogFile

		My-Logger "Disconnecting from new VCSA ..."
        Disconnect-VIServer -Confirm:$false
	}
}

$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes,2)

My-Logger "$VCFInstallerProductSKU 9 Lab Deployment Complete!"
My-Logger "`tStartTime: $StartTime" -color cyan
My-Logger "`tEndTime: $EndTime" -color cyan
My-Logger "`tDuration: $duration minutes to deploy VCF Installer, Nested ESX VMs & start $VCFInstallerProductSKU Deployment" -color cyan
