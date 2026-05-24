# Physical vCenter Server environment
$VIServer = "172.30.0.13"
$VIUsername = "administrator@vsphere.local"
$VIPassword = "VMware1!VMware1!"

# General Deployment Configuration
$VAppLabel = "AbbedSedkaoui-VVF9"
$VMDatacenter = "VVF-Datacenter"
$VMCluster = "VVF-Mgmt-Cluster"
$VMDatastoreMGMT = "NFS01-Rocky"
$VMNetmask = "255.255.255.0"
$VMGateway = "10.11.10.53"
$VMNestedESXiMgmtGateway = "10.11.11.53" # Download VCF9 workbook at this link https://techdocs.broadcom.com/content/dam/broadcom/techdocs/us/en/assets/vmware-cis/vcf/vcf-9.0-planning-and-preparation-workbook.xlsx
$VMNestedESXiWldGateway = "10.13.11.53"
$VMDNS = "192.168.1.100"
$VMNTP = "dc-pc2.abidi.systems"
$VMPassword = "VMware1!"
$VMDomain = "abidi.systems"
$VMSyslog = "10.11.10.250"
$VMFolder = "abs"

# Vlan and Portgroup Vlan Configuration for Nested Management Domain ranging from 0 to 4094 except TEP ranging from 1 to 4094
$VMNetwork = "DVPG_FOR_VMTRUNK" # on physical host DVPG must be Vlan 4095 
$VCFInstallerNetwork = "DVPG_FOR_1110-NETWORK" # on physical host PG on ESX02 or DVPG, must be same Vlan as $NestedVMNetworkVLanId (used to be called Infrastructure Network in VCF 5.x workbook)
$NestedVMNetworkVLanId = 1110
$vmk0MgmtVLanId = 1111 # it is different to follow VMware Validated Solutions (VVS) VCF Workbook Planning Peparation and VCF Design Best Practices
$vmotionVlanId = 1112
$vsanVlanId = 1113
$esxiNSXTepVlanId = 1114

# Enable Debugging
$Debug = $false

# Full Path to both the Nested ESXi & VCF Installer OVA
$NestedESXiApplianceOVA = "E:\Offline-Depot-9.0.2.0\PROD\COMP\ESX_HOST\Nested_ESXi9.0.2_Appliance_Template_v1.0.ova"
$VCFInstallerOVA = "E:\Offline-Depot-9.0.2.0\PROD\COMP\SDDC_MANAGER_VCF\VCF-SDDC-Manager-Appliance-9.0.2.0.25151285.ova"

# VCF Version
$VCFInstallerProductVersion = "9.0.2.0"
$VCFInstallerProductSKU = "VVF"

# VCF Software Depot Configuration
$VCFInstallerSoftwareDepot = "offline" #online or offline
$VCFInstallerDepotToken = ""

# Offline Depot Configurations (optional)
$VCFInstallerDepotUsername = "vcf"
$VCFInstallerDepotPassword = "vcf123!"
$VCFInstallerDepotHost = "192.168.1.250"
$VCFInstallerDepotPort = 8888
$VCFInstallerDepotHttps = $false

# VCF Fleet Deployment Configuration
$DeploymentInstanceName = "Abbed VVF 9 Instance"
$DeploymentId = "vvf-m01"
$CEIPEnabled = $true
$FIPSEnabled = $true

# VCF Installer Configurations
$VCFInstallerVMName = "inst01"
$VCFInstallerFQDN = "inst01.abidi.systems"
$VCFInstallerIP = "10.11.10.10"
$VCFInstallerAdminUsername = "admin@local"
$VCFInstallerAdminPassword = "VMware1!VMware1!"
$VCFInstallerRootPassword = "VMware1!VMware1!"

# VCF Installer VM Resources
$VCFInstallerVMvCPU = "2"
$VCFInstallerVMvMEM = "8" #GB

# VCF Installer Setup
$VCFFeatureProperties = @{
    "feature.vcf.internal.single.host.domain" = "true"
    "feature.vcf.vgl-43370.vsan.esa.sddc.managed.disk.claim" = "true"
}

$VCFDomainManagerProperties = @{
    "enable.speed.of.physical.nics.validation" = "false"
    "vsan.esa.sddc.managed.disk.claim" = "true"
}

# Nested ESXi VMs for Management Domain
$NestedESXiHostnameToIPsForManagementDomain = @{
    "esx01" = "10.11.11.1"
    "esx02" = "10.11.11.2"
    "esx03" = "10.11.11.3"
}

# Nested ESXi VM Resources for Management Domain
$NestedESXiMGMTvCPU = "8"
$NestedESXiMGMTvMEM = "24" #GB #Tips: 122GB for VCF single node with Wld VMs or 114GB for 2 nodes and with VCF automation enabled "$noVCFAutomation = 0" in sample but without Wld VMs "$deployNestedESXiVMsForWLD = 0" in deployment script
$NestedESXiMGMTCachingvDisk = "32" #GB
$NestedESXiMGMTCapacityvDisk = "100" #GB
$NestedESXiMGMTBootDisk = "64" #GB
$NestedESXiMGMTvGuestOS = "vmkernel9Guest" # default vmkernel8Guest
$NestedESXiMGMTvHardwareVersion = "vmx-22" # default vmx-20, vmx-21 nvme 1.3c, vmx-22 nvme 1.4

# VM Network configuration
$NestedVmManagementNetworkCidr = "10.11.10.0/24"

# ESXi Networks Configuration for Mgmt Domain
$NestedESXiManagementNetworkCidr = "10.11.11.0/24"
$NestedESXivMotionNetworkCidr = "10.11.12.0/24"
$NestedESXivSANNetworkCidr = "10.11.13.0/24"
$NestedESXiNSXTepNetworkCidr = "10.11.14.0/24"

# vCenter Configuration
$VCSAName = "vc01"
$VCSAIP = "10.11.10.13"
$VCSARootPassword = "VMware1!VMware1!"
$VCSASSOPassword = "VMware1!VMware1!"
$VCSASSODomainName = "vsphere.local"
$VCSASSOUserName = "administrator@$VCSASSODomainName"
$VCSASize = "tiny" # default is small, tiny is good enough for LAB/POC seeing the number of VMs. ref. configmax
$VCSAEnableVCLM = $true
$VCSADatacenterName = "vcf-mgmt-dc"
$VCSAClusterName = "vcf-mgmt-cl01"
$VCSAclusterEvcMode = "" #One among: INTEL_MEROM, INTEL_PENRYN, INTEL_NEALEM, INTEL_WESTMERE, INTEL_SANDYBRIDGE, INTEL_IVYBRIDGE, INTEL_HASWELL, INTEL_BROADWELL, INTEL_SKYLAKE, INTEL_CASCADELAKE, INTEL_ICELAKE, INTEL_SAPPHIRERAPIDS, AMD_REV_E, AMD_REV_F, AMD_GREYHOUND_NO3DNOW, AMD_GREYHOUND, AMD_BULLDOZER, AMD_PILEDRIVER, AMD_STREAMROLLER, AMD_ZEN, AMD_ZEN2, AMD_ZEN3, AMD_ZEN4

#vSAN Configuration
$VSANFTT = 0
$VSANDedupe = $false
$VSANESAEnabled = $false
$VSANDatastoreName = "vsanDatastore"

# VCF Operations Configuration
$VCFOperationsSize = "xsmall" # default is small, xsmall is for under 700 objects here we're at ~200 good enough for POC/LAB. ref https://knowledge.broadcom.com/external/article/397782/vcf-operations-90-sizing-guidelines.html
$VCFOperationsHostname = "vcf01"
$VCFOperationsIP = "10.11.10.12"
$VCFOperationsRootPassword = "VMware1!VMware1!"
$VCFOperationsAdminPassword = "VMware1!VMware1!"

