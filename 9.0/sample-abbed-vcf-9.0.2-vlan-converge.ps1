# Physical vCenter Server environment
$VIServer = "172.30.0.13"
$VIUsername = "administrator@vsphere.local"
$VIPassword = "VMware1!VMware1!"

# General Deployment Configuration
$VAppLabel = "AbbedSedkaoui-VCF9.0-Converge"
$VMDatacenter = "VCF-Datacenter"
$VMCluster = "VCF-Mgmt-Cluster"
$VMDatastoreMGMT = "local-vmfs-datastore-2"
$VMDatastoreWLD = "local-vmfs-datastore-1"
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
$VMNetwork = "VMTRUNK" # on physical host DVPG must be Vlan 4095 
$VCFInstallerNetwork = "1110-Network" # on physical host PG on ESX02 or DVPG, must be same Vlan as $NestedVMNetworkVLanId (used to be called Infrastructure Network in VCF 5.x workbook)
$NestedVMNetworkVLanId = 1110
$vmk0MgmtVLanId = 1111 # it is different to follow VMware Validated Solutions (VVS) VCF Workbook Planning Peparation and VCF Design Best Practices
$vmotionVlanId = 1112
$vsanVlanId = 1113
$esxiNSXTepVlanId = 1114

# Vlan Configuration for Nested Workload Domain
$vmk0WldVLanId = 1311
$vmotionWldVlanId = 1312
$vsanWldVlanId = 1313
$esxiWldNSXTepVlanId = 1314


# Enable Debugging
$Debug = $false

# Full Path to both the Nested ESXi & VCF Installer OVA & VCSA extracted ISO
$NestedESXiApplianceOVA = "E:\DL\VCF-5.2.2\Nested_ESXi8.0u3h_Appliance_Template_v1.ova"
$VCFInstallerOVA = "E:\Offline-Depot-9.0.2.0\PROD\COMP\SDDC_MANAGER_VCF\VCF-SDDC-Manager-Appliance-9.0.2.0100.25602461.ova" 
$VCSAInstallerPath = "E:\DL\VCF-5.2.2\VMware-VCSA-all-8.0.3-25092719" 
$NSXTManagerOVA = "E:\DL\VCF-5.2.2\nsx-unified-appliance-4.2.3.2.0.25077149.ova"

# vSphere VLCM image
$VCSAVLCMversion = "8.0 U3h - 25067014" # retrieve prior to deployment the uiString of the baseimage of the desired NestedESXi so that the script can extract it for vLCM Cluster using: `esxcli software baseimage get | grep Display | cut -c21-39`
# VCF Version
$VCFInstallerProductVersion = "9.0.2.0"
$VCFInstallerProductSKU = "VCF"

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
$DeploymentInstanceName = "Abbed VCF 9.0.2 Instance"
$DeploymentId = "vcf-m01"
$CEIPEnabled = $true
$FIPSEnabled = $true

# VCF Installer Configurations
$VCFInstallerVMName = "inst01"
$VCFInstallerFQDN = "inst01.abidi.systems"
$VCFInstallerIP = "10.11.10.10"
$VCFInstallerAdminUsername = "admin@local" # do not change
$VCFInstallerAdminPassword = "VMware1!VMware1!"
$VCFInstallerRootPassword = "VMware1!VMware1!"

# VCF Installer VM Resources
$VCFInstallerVMvCPU = "2"
$VCFInstallerVMvMEM = "8" #GB

# VCF Installer Setup
$VCFDomainManagerProperties = @{
    "validation.disable.network.connectivity.check" = "true"
    "nsxt.mtu.validation.skip" = "true"
    "vsan.esa.sddc.managed.disk.claim" = "true"
}

$VCFFeatureProperties = @{
    "feature.vcf.internal.single.host.domain" = "true"
    "feature.vcf.vgl-43370.vsan.esa.sddc.managed.disk.claim" = "true"
}

# SDDC Manager Configuration
$SddcManagerHostname = "sddcm01"
$SddcManagerFQDN = "sddcm01.abidi.systems"
$SddcManagerIP = "10.11.10.11"
$SddcManagerRootPassword = "VMware1!VMware1!"
$SddcManagerVcfPassword = "VMware1!VMware1!"
$SddcManagerSSHPassword = "VMware1!VMware1!"
$SddcManagerLocalPassword = "VMware1!VMware1!"

# Nested ESXi VMs for Management Domain
$NestedESXiHostnameToIPsForManagementDomain = @{
    "esx01" = "10.11.11.1" # workaround import guardrails autmatically active if less 3 ESXi
    #"esx02" = "10.11.11.2"
    #"esx03" = "10.11.11.3"
    #"esx04" = "10.11.11.4"
}

# Nested ESXi VMs for Workload Domain
$NestedESXiHostnameToIPsForWorkloadDomain = @{
    "esx05" = "10.13.11.5"
    "esx06" = "10.13.11.6"
    #"esx07" = "10.13.11.7"
}

# Nested ESXi VM Resources for Management Domain
$NestedESXiMGMTvCPU = "24"
$NestedESXiMGMTvMEM = "122" #GB #Tips: 122GB for VCF single node with Wld VMs or 114GB for 2 nodes and with VCF automation enabled "$noVCFAutomation = 0" in sample but without Wld VMs "$deployNestedESXiVMsForWLD = 0" in deployment script
$NestedESXiMGMTCachingvDisk = "32" #GB
$NestedESXiMGMTCapacityvDisk = "2000" #GB
$NestedESXiMGMTBootDisk = "64" #GB
$NestedESXiMGMTvGuestOS = "vmkernel9Guest" # default vmkernel8Guest
$NestedESXiMGMTvHardwareVersion = "vmx-22" # default vmx-20, vmx-21 nvme 1.3c, vmx-22 nvme 1.4
$entropySourcesMGMT = 6 # 2 = RDRAND for Zen4/5 is Recommended by VCF Egineering, 4 = RDSEED is default for FIPS, 6 = To combine Ref. P5 https://www.vmware.com/docs/AGD_ESXi8f_EntropyGuide_v1.0

# Nested ESXi VM Resources for Workload Domain
$NestedESXiWLDvCPU = "12"
$NestedESXiWLDvMEM = "64" #GB
$NestedESXiWLDCachingvDisk = "32" #GB
$NestedESXiWLDCapacityvDisk = "250" #GB
$NestedESXiWLDBootDisk = "64" #GB
$entropySourcesWLD = 6 # 2 = RDRAND for Zen4/5 is Recommended by VCF Engineering, 4 = RDSEED is default for FIPS, 6 = To combine Ref. P5 https://www.vmware.com/docs/AGD_ESXi8f_EntropyGuide_v1.0

# VM Network configuration
$NestedVmManagementNetworkCidr = "10.11.10.0/24"

# ESXi Networks Configuration for Mgmt Domain
$NestedESXiManagementNetworkCidr = "10.11.11.0/24"
$NestedESXivMotionNetworkCidr = "10.11.12.0/24"
$NestedESXivSANNetworkCidr = "10.11.13.0/24"
$NestedESXiNSXTepNetworkCidr = "10.11.14.0/24"

# ESXi Networks Configuration for Wld Domain
$NestedESXiManagementWldDomainNetworkCidr = "10.13.11.0/24"
$NestedESXivMotionWldDomainNetworkCidr = "10.13.12.0/24"
$NestedESXivSANWldDomainNetworkCidr = "10.13.13.0/24"
$NestedESXiNSXTepWldDomainNetworkCidr = "10.13.14.0/24"

# vCenter Configuration
$VCSAName = "vc01"
$VCSAIP = "10.11.10.13"
$VCSAPrefix = "24"
$VCSARootPassword = "VMware1!VMware1!"
$VCSASSOPassword = "VMware1!VMware1!"
$VCSASSODomainName = "vsphere.local"
$VCSASSOUserName = "administrator@$VCSASSODomainName"
$VCSASSHEnable = "true"
$VCSASize = "tiny" # default is small since VCF 9.1, tiny is good enough for VCF 9.0 LAB/POC seeing the number of VMs. ref. configmax
$VCSADatacenterName = "vcf-m01-dc01"
$VCSAClusterName = "vcf-m01-cl01"
$VCSAVDS = "vcf-m01-cl01-vds01"
$VCSAVDSMTU = 9000 # Needs to match your physical MTU
$VCSAMgmtPortgroupName = "DVPG_FOR_MANAGEMENT"
$VCSAVMNetworkPortgroupName = "DVPG_FOR_VM_MANAGEMENT"
$VCSAVSanPortgroupName = "DVPG_FOR_VSAN"
$VCSAclusterEvcMode = "" # One among: INTEL_MEROM, INTEL_PENRYN, INTEL_NEALEM, INTEL_WESTMERE, INTEL_SANDYBRIDGE, INTEL_IVYBRIDGE, INTEL_HASWELL, INTEL_BROADWELL, INTEL_SKYLAKE, INTEL_CASCADELAKE, INTEL_ICELAKE, INTEL_SAPPHIRERAPIDS, AMD_REV_E, AMD_REV_F, AMD_GREYHOUND_NO3DNOW, AMD_GREYHOUND, AMD_BULLDOZER, AMD_PILEDRIVER, AMD_STREAMROLLER, AMD_ZEN, AMD_ZEN2, AMD_ZEN3, AMD_ZEN4
$VCSAuseExistingDeploymentvCenter = 1 # set this to 1 to trigger deployment of vCenter and following VCF brownfield converge workflow

#vSAN Configuration
$VSANStoragePolicyName = "vsan-ftt-storage-policy"
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

# NSX Configuration
$NSXManagerSize = "medium" # mandatory minimum form factor
$NSXManagerVIPHostname = "nsx01.abidi.systems"
$NSXManagerVIPIP  = "10.11.10.14"
$NSXManagerHostnameToIPsForManagementDomain = @{
    "nsx01a" = "10.11.10.15" # workaround import guardrails autmatically active if less 3 NSX Manager
    "nsx02a" = "10.11.10.16"
    "nsx03a" = "10.11.10.17"
}
$NSXManagerNode1DisplayName = "nsx01a"

$NSXTMgrvCPU = "6" # override default medium size
$NSXTMgrvMEM = "16" # override default medium size
$NSXRootPassword = "VMware1!VMware1!"
$NSXAdminUsername = "admin"
$NSXAdminPassword = "VMware1!VMware1!"
$NSXAuditUsername = "audit"
$NSXAuditPassword = "VMware1!VMware1!"
$NSXSSHEnableVar = $true
$NSXRootPasswordVar = $true
$NSXuseExistingDeploymentNSX = 1 # set this to 1 to trigger deployment of NSX and following VCF brownfield converge workflow

# VCF Operations Collector
$VCFOperationsCollectorSize = "small" # default small. ref link above
$VCFOperationsCollectorHostname = "opsproxy01"
$VCFOperationsCollectorRootPassword = "VMware1!VMware1!"

# VCF Operations Fleet Manager
$VCFOperationsFleetManagerHostname = "opsfm01"
$VCFOperationsFleetManagerAdminPassword = "VMware1!VMware1!"
$VCFOperationsFleetManagerRootPassword = "VMware1!VMware1!"

# VCF Automation
$VCFAutomationHostname = "auto01"
$VCFAutomationAdminPassword = "VMware1!VMware1!"
$VCFAutomationIPPool = @("10.11.10.23","10.11.10.24")
$VCFAutomationNodePrefix = "vcf-abs-auto"
$VCFAutomationClusterCIDR = "198.18.0.0/15"

# Set to 1 only if you do not want VCF Automation to be deployed in the bringup
$noVCFAutomation = 1

# VCF Workload Domain Configurations
$VCFWorkloadDomainName = "vcf-w01"
$VCFWorkloadDomainOrgName = "vcf-w01"
$VCFWorkloadDomainEnableVCLM = $true
$VCFWorkloadDomainEnableVSANESA = $false
$VCFWorkloadDomainPoolName = "vcf-w01-rp01"
$VCFWorkloadDomainPoolFile = "networkPoolSpec.json"


# WLD vCenter Configuration
$VCFWorkloadDomainVCSAHostname = "vc02"
$VCFWorkloadDomainVCSAIP = "10.11.10.40"
$VCFWorkloadDomainVCSARootPassword = "VMware1!VMware1!"
$VCFWorkloadDomainVCSASSOPassword = "VMware1!VMware1!"
$VCFWorkloadDomainVCSADatacenterName = "vcf-wld-dc"
$VCFWorkloadDomainVCSAClusterName = "vcf-wld-cl01"

# WLD NSX Configuration
$VCFWorkloadDomainNSXManagerVIPHostname = "nsx02" # remember to create DNS A record with associated IP, 10.11.10.41 in this case
$VCFWorkloadDomainNSXManagerNode1Hostname = "nsx02a" 
$VCFWorkloadDomainNSXManagerNode1IP = "10.11.10.42"
$VCFWorkloadDomainNSXAdminPassword = "VMware1!VMware1!"
$VCFWorkloadDomainSeparateNSXSwitch = $true
$VCFWorkloadDomainNSXManagerSize = "small"
# Physical vCenter Server environment
$VIServer = "172.30.0.13"
$VIUsername = "administrator@vsphere.local"
$VIPassword = "VMware1!VMware1!"

# General Deployment Configuration
$VAppLabel = "AbbedSedkaoui-VCF9.0-Converge"
$VMDatacenter = "VCF-Datacenter"
$VMCluster = "VCF-Mgmt-Cluster"
$VMDatastoreMGMT = "local-vmfs-datastore-1"
$VMDatastoreWLD = "local-vmfs-datastore-2"
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
$VMNetwork = "VMTRUNK" # on physical host DVPG must be Vlan 4095 
$VCFInstallerNetwork = "1110-Network" # on physical host PG on ESX02 or DVPG, must be same Vlan as $NestedVMNetworkVLanId (used to be called Infrastructure Network in VCF 5.x workbook)
$NestedVMNetworkVLanId = 1110
$vmk0MgmtVLanId = 1111 # it is different to follow VMware Validated Solutions (VVS) VCF Workbook Planning Peparation and VCF Design Best Practices
$vmotionVlanId = 1112
$vsanVlanId = 1113
$esxiNSXTepVlanId = 1114

# Vlan Configuration for Nested Workload Domain
$vmk0WldVLanId = 1311
$vmotionWldVlanId = 1312
$vsanWldVlanId = 1313
$esxiWldNSXTepVlanId = 1314


# Enable Debugging
$Debug = $false

# Full Path to both the Nested ESXi & VCF Installer OVA & VCSA extracted ISO
$NestedESXiApplianceOVA = "E:\VCF-5.2.2\Nested_ESXi8.0u3g_Appliance_Template_v1.ova"
$VCFInstallerOVA = "E:\Offline-Depot-9.0.2.0\PROD\COMP\SDDC_MANAGER_VCF\VCF-SDDC-Manager-Appliance-9.0.2.0.25151285.ova" 
$VCSAInstallerPath = "E:\VCF-5.2.2\VMware-VCSA-all-8.0.3-24853646" 
$NSXTManagerOVA = "E:\VCF-5.2.2\nsx-unified-appliance-4.2.3.0.0.24866352.ova"

# vSphere VLCM image
$VCSAVLCMversion = "8.0 U3g - 24859861" # retrieve prior to deployment the uiString of the baseimage of the desired NestedESXi so that the script can extract it for vLCM Cluster using: `esxcli software baseimage get | grep Display | cut -c21-39`
# VCF Version
$VCFInstallerProductVersion = "9.0.2.0"
$VCFInstallerProductSKU = "VCF"

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
$DeploymentInstanceName = "Abbed VCF 9.0.2 Instance"
$DeploymentId = "vcf-m01"
$CEIPEnabled = $true
$FIPSEnabled = $true

# VCF Installer Configurations
$VCFInstallerVMName = "inst01"
$VCFInstallerFQDN = "inst01.abidi.systems"
$VCFInstallerIP = "10.11.10.10"
$VCFInstallerAdminUsername = "admin@local" # do not change
$VCFInstallerAdminPassword = "VMware1!VMware1!"
$VCFInstallerRootPassword = "VMware1!VMware1!"

# VCF Installer VM Resources
$VCFInstallerVMvCPU = "2"
$VCFInstallerVMvMEM = "8" #GB

# VCF Installer Setup
$VCFDomainManagerProperties = @{
    "validation.disable.network.connectivity.check" = "true"
    "nsxt.mtu.validation.skip" = "true"
    "vsan.esa.sddc.managed.disk.claim" = "true"
}

$VCFFeatureProperties = @{
    "feature.vcf.internal.single.host.domain" = "true"
    "feature.vcf.vgl-43370.vsan.esa.sddc.managed.disk.claim" = "true"
}

# SDDC Manager Configuration
$SddcManagerHostname = "sddcm01"
$SddcManagerFQDN = "sddcm01.abidi.systems"
$SddcManagerIP = "10.11.10.11"
$SddcManagerRootPassword = "VMware1!VMware1!"
$SddcManagerVcfPassword = "VMware1!VMware1!"
$SddcManagerSSHPassword = "VMware1!VMware1!"
$SddcManagerLocalPassword = "VMware1!VMware1!"

# Nested ESXi VMs for Management Domain
$NestedESXiHostnameToIPsForManagementDomain = @{
    "esx01" = "10.11.11.1"
    #"esx02" = "10.11.11.2"
    #"esx03" = "10.11.11.3"
    #"esx04" = "10.11.11.4"
}

# Nested ESXi VMs for Workload Domain
$NestedESXiHostnameToIPsForWorkloadDomain = @{
    "esx05" = "10.13.11.5"
    "esx06" = "10.13.11.6"
    #"esx07" = "10.13.11.7"
}

# Nested ESXi VM Resources for Management Domain
$NestedESXiMGMTvCPU = "24"
$NestedESXiMGMTvMEM = "122" #GB #Tips: 122GB for VCF single node with Wld VMs or 114GB for 2 nodes and with VCF automation enabled "$noVCFAutomation = 0" in sample but without Wld VMs "$deployNestedESXiVMsForWLD = 0" in deployment script
$NestedESXiMGMTCachingvDisk = "32" #GB
$NestedESXiMGMTCapacityvDisk = "2000" #GB
$NestedESXiMGMTBootDisk = "64" #GB
$NestedESXiMGMTvGuestOS = "vmkernel9Guest" # default vmkernel8Guest
$NestedESXiMGMTvHardwareVersion = "vmx-22" # default vmx-20, vmx-21 nvme 1.3c, vmx-22 nvme 1.4
$entropySourcesMGMT = 6 # 2 = RDRAND for Zen4/5 is Recommended by VCF Egineering, 4 = RDSEED is default for FIPS, 6 = To combine Ref. P5 https://www.vmware.com/docs/AGD_ESXi8f_EntropyGuide_v1.0

# Nested ESXi VM Resources for Workload Domain
$NestedESXiWLDvCPU = "12"
$NestedESXiWLDvMEM = "64" #GB
$NestedESXiWLDCachingvDisk = "32" #GB
$NestedESXiWLDCapacityvDisk = "250" #GB
$NestedESXiWLDBootDisk = "64" #GB
$entropySourcesWLD = 6 # 2 = RDRAND for Zen4/5 is Recommended by VCF Engineering, 4 = RDSEED is default for FIPS, 6 = To combine Ref. P5 https://www.vmware.com/docs/AGD_ESXi8f_EntropyGuide_v1.0

# VM Network configuration
$NestedVmManagementNetworkCidr = "10.11.10.0/24"

# ESXi Networks Configuration for Mgmt Domain
$NestedESXiManagementNetworkCidr = "10.11.11.0/24"
$NestedESXivMotionNetworkCidr = "10.11.12.0/24"
$NestedESXivSANNetworkCidr = "10.11.13.0/24"
$NestedESXiNSXTepNetworkCidr = "10.11.14.0/24"

# ESXi Networks Configuration for Wld Domain
$NestedESXiManagementWldDomainNetworkCidr = "10.13.11.0/24"
$NestedESXivMotionWldDomainNetworkCidr = "10.13.12.0/24"
$NestedESXivSANWldDomainNetworkCidr = "10.13.13.0/24"
$NestedESXiNSXTepWldDomainNetworkCidr = "10.13.14.0/24"

# vCenter Configuration
$VCSAName = "vc01"
$VCSAIP = "10.11.10.13"
$VCSAPrefix = "24"
$VCSARootPassword = "VMware1!VMware1!"
$VCSASSOPassword = "VMware1!VMware1!"
$VCSASSODomainName = "vsphere.local"
$VCSASSOUserName = "administrator@$VCSASSODomainName"
$VCSASSHEnable = "true"
$VCSASize = "tiny" # default is small since VCF 9.1, tiny is good enough for VCF 9.0 LAB/POC seeing the number of VMs. ref. configmax
$VCSADatacenterName = "vcf-m01-dc01"
$VCSAClusterName = "vcf-m01-cl01"
$VCSAVDS = "vcf-m01-cl01-vds01"
$VCSAVDSMTU = 9000 # Needs to match your physical MTU
$VCSAMgmtPortgroupName = "DVPG_FOR_MANAGEMENT"
$VCSAVMNetworkPortgroupName = "DVPG_FOR_VM_MANAGEMENT"
$VCSAVSanPortgroupName = "DVPG_FOR_VSAN"
$VCSAclusterEvcMode = "" # One among: INTEL_MEROM, INTEL_PENRYN, INTEL_NEALEM, INTEL_WESTMERE, INTEL_SANDYBRIDGE, INTEL_IVYBRIDGE, INTEL_HASWELL, INTEL_BROADWELL, INTEL_SKYLAKE, INTEL_CASCADELAKE, INTEL_ICELAKE, INTEL_SAPPHIRERAPIDS, AMD_REV_E, AMD_REV_F, AMD_GREYHOUND_NO3DNOW, AMD_GREYHOUND, AMD_BULLDOZER, AMD_PILEDRIVER, AMD_STREAMROLLER, AMD_ZEN, AMD_ZEN2, AMD_ZEN3, AMD_ZEN4
$VCSAuseExistingDeploymentvCenter = 1 # set this to 1 to trigger deployment of vCenter and following VCF brownfield converge workflow

#vSAN Configuration
$VSANStoragePolicyName = "vsan-ftt-storage-policy"
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

# NSX Configuration
$NSXManagerSize = "medium" # mandatory minimum form factor
$NSXManagerVIPHostname = "nsx01.abidi.systems"
$NSXManagerVIPIP  = "10.11.10.14"
$NSXManagerNode1DisplayName = "nsx01a"
$NSXManagerNode1Hostname = "nsx01a.abidi.systems"
$NSXManagerNode1IP = "10.11.10.15"

$NSXTMgrvCPU = "6" #override default medium size
$NSXTMgrvMEM = "18" #override default medium size
$NSXRootPassword = "VMware1!VMware1!"
$NSXAdminUsername = "admin"
$NSXAdminPassword = "VMware1!VMware1!"
$NSXAuditUsername = "audit"
$NSXAuditPassword = "VMware1!VMware1!"
$NSXSSHEnableVar = $true
$NSXRootPasswordVar = $true
$NSXuseExistingDeploymentNSX = 1 # set this to 1 to trigger deployment of NSX and following VCF brownfield converge workflow

# VCF Operations Collector
$VCFOperationsCollectorSize = "small" # default small. ref link above
$VCFOperationsCollectorHostname = "opsproxy01"
$VCFOperationsCollectorRootPassword = "VMware1!VMware1!"

# VCF Operations Fleet Manager
$VCFOperationsFleetManagerHostname = "opsfm01"
$VCFOperationsFleetManagerAdminPassword = "VMware1!VMware1!"
$VCFOperationsFleetManagerRootPassword = "VMware1!VMware1!"

# VCF Automation
$VCFAutomationHostname = "auto01"
$VCFAutomationAdminPassword = "VMware1!VMware1!"
$VCFAutomationIPPool = @("10.11.10.23","10.11.10.24")
$VCFAutomationNodePrefix = "vcf-abs-auto"
$VCFAutomationClusterCIDR = "198.18.0.0/15"

# Set to 1 only if you do not want VCF Automation to be deployed in the bringup
$noVCFAutomation = 1

# VCF Workload Domain Configurations
$VCFWorkloadDomainName = "vcf-w01"
$VCFWorkloadDomainOrgName = "vcf-w01"
$VCFWorkloadDomainEnableVCLM = $true
$VCFWorkloadDomainEnableVSANESA = $false
$VCFWorkloadDomainPoolName = "vcf-w01-rp01"
$VCFWorkloadDomainPoolFile = "networkPoolSpec.json"


# WLD vCenter Configuration
$VCFWorkloadDomainVCSAHostname = "vc02"
$VCFWorkloadDomainVCSAIP = "10.11.10.40"
$VCFWorkloadDomainVCSARootPassword = "VMware1!VMware1!"
$VCFWorkloadDomainVCSASSOPassword = "VMware1!VMware1!"
$VCFWorkloadDomainVCSADatacenterName = "vcf-wld-dc"
$VCFWorkloadDomainVCSAClusterName = "vcf-wld-cl01"

# WLD NSX Configuration
$VCFWorkloadDomainNSXManagerVIPHostname = "nsx02" # remember to create DNS A record with associated IP, 10.11.10.41 in this case
$VCFWorkloadDomainNSXManagerNode1Hostname = "nsx02a" 
$VCFWorkloadDomainNSXManagerNode1IP = "10.11.10.42"
$VCFWorkloadDomainNSXAdminPassword = "VMware1!VMware1!"
$VCFWorkloadDomainSeparateNSXSwitch = $true
$VCFWorkloadDomainNSXManagerSize = "small"
