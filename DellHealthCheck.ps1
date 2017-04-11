#####################################################################################################################
#														    #
#	Get-DellHealth - A PowerShell module to pull the Dell hardware health using SNMP. The module will detect    #
#			whether connecting to an iDRAC (7 or above) or the OpenManage package on Windows	    #
#														    #
#	Written By: John Salle											    #
#	Last Updated: 4/10/2017											    #
#														    #
#														    #
#	SNMP Library used from http://sharpsnmplib.codeplex.com/						    #
#	Get-SNMP adapted from https://vwiki.co.uk/SNMP_and_PowerShell						    #
#	(Both licensed under Open Source licenses)								    #
#														    #
#	Short URL: https://goo.gl/uIVXKD		#
#														    #
#####################################################################################################################
[cmdletbinding()]
Param(
	[string]$snmplibpath = ".\SharpSnmpLib.dll"
)

#Set constant SNMP status variables
$OTHER = 1
$UNKNOWN = 2
$OK = 3
$WARNING = 4
$CRITICAL = 5

#Loads the Sharp SNMP Library
#Can be downloaded from here (you only need the SharpSnmpLib.dll file):
#http://sharpsnmplib.codeplex.com/releases/view/79079
[reflection.assembly]::LoadFrom( (Resolve-Path $snmplibpath) ) | out-null


function Get-DellHealthStatus() {
        [cmdletbinding()]
	Param(
		[string]$ip,
		[string]$comm = "public",
		[int]$port=161, 
		[int]$timeout=3000
	)
	
	$global:type = Get-HardwareType $ip $comm $timeout
	
	switch($type){
	
				1 { $globalSystemStatus = ".1.3.6.1.4.1.674.10892.1.300.10.1.4.1"	}
				2 { $globalSystemStatus = "1.3.6.1.4.1.674.10892.5.4.200.10.1.2.1" }
	}
	
	$snmpCheck = (Get-SNMP  $IP  $globalSystemStatus  $Comm $port $timeout).Data
	switch ($snmpCheck){
		
		$OTHER	{Write-Host "WARNING: " $model}
		$UNKNOWN {Write-Host "WARNING: " $model}
		$OK	{Write-Host "OK: " $model}
		$WARNING {Write-Host "WARNING: " $model}
		$CRITICAL {Write-Host "CRITICAL: " $model}
		default {Write-Host "Error: " $snmpCheck}
			
		}
		
		Write-Verbose "Verbose Output" 
		if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent){
			Get-DellStorageStatus $IP $Comm
		
		
		}
		
}
function Get-DellStorageStatus([string]$ip,[string]$comm = "public", [int]$port=161){
		
$states = @{
	1 = "Unknown";
	2 = "Ready";
	3 = "Online";
	4 = "Foreign";
	5 = "Offline";
	6 = "Blocked";
	7 = "Failed";
	8 = "Non-Raid";
	9 = "Removed";
	10 = "Read Only"
}	
	
$vstates = @{
	1 = "Unknown";
	2 = "Online";
	3 = "Failed";
	4 = "Degraded";
}
	
$raid = @{
	1 = "None"; 
	2 = "RAID-0";
	3 = "RAID-1";
	4 = "RAID-5";
	5 = "RAID-6";
	6 = "RAID-10";
	7 = "RAID-50";
	8 = "RAID-60";
	9 = "Concatenated RAID 1"
	10 = "Concatenated RAID 5"
}
		
	
	switch($type){
		
					1 { $enclosureDriveCount = ""
							$physicalDiskNumber = ".1.3.6.1.4.1.674.10893.1.20.130.4.1.1"
							$physicalDiskName = ".1.3.6.1.4.1.674.10893.1.20.130.4.1.2"
							$physicalDiskState = ".1.3.6.1.4.1.674.10893.1.20.130.4.1.4"
							$physicalDiskCapacityInMB = ".1.3.6.1.4.1.674.10893.1.20.130.4.1.11"
							$virtualDiskNumber = ".1.3.6.1.4.1.674.10893.1.20.140.1.1.1"
							$virtualDiskName = ".1.3.6.1.4.1.674.10893.1.20.140.1.1.2"
							$virtualDiskState = ".1.3.6.1.4.1.674.10893.1.20.140.1.1.4"
							$virtualDiskLayout = ".1.3.6.1.4.1.674.10893.1.20.140.1.1.13"
							$virtualDiskSizeInMB = ".1.3.6.1.4.1.674.10893.1.20.140.1.1.6"
							}
					2 { $enclosureDriveCount = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.3.1.31.1"
							$physicalDiskNumber = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.1"
							$physicalDiskName = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.2"
							$physicalDiskState = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.4"
							$physicalDiskCapacityInMB = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.11"
							$virtualDiskNumber = ".1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.1"
							$virtualDiskName = ".1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.2"
							$virtualDiskState = ".1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.4"
							$virtualDiskLayout = ".1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.13"
							$virtualDiskSizeInMB = ".1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.6"
							
						}
						
		}
		
		$pDiskCount = 0
		Do {
			Try {
				$j=$j+1
				$snmp_out =  (Get-SNMP $IP "$physicalDiskNumber.$j" $comm $port).Data
			}
			Catch {
				$snmp_out = ""
			}
			

		} Until(($snmp_out -contains "NoSuchInstance") -or ([string]::IsNullOrEmpty($snmp_out)))
		
		$pDiskCount = $($j-1)
		Write-Verbose "Number of Physical Drives: $pDiskCount"
		for ($i = 1; $i -le $pDiskCount; $i++){ #Parse through each drive
				$diskName = (Get-SNMP $ip "$physicalDiskName.$i" $comm).Data
				$diskStatus = (Get-SNMP $ip "$physicalDiskState.$i" $comm).Data
				$diskCapacityInMB = (Get-SNMP $ip "$physicalDiskCapacityInMB.$i" $comm).Data
				Write-Verbose "$diskName | Status: $($states.Item([Int32]$diskStatus)) | Capacity (MB): $diskCapacityInMB"
							
		}
		
		$j=0 ; $vDiskCount = 0 #Counts number of virtual disks present
		Do {
			Try {
				$j=$j+1
				$snmp_out =  (Get-SNMP $IP "$virtualDiskNumber.$j" $comm $port).Data
			}
			Catch {
				$snmp_out = ""
			}
		}
		Until($snmp_out -contains "NoSuchInstance" -or ([string]::IsNullOrEmpty($snmp_out)))

		Write-Verbose "Number of Virtual Disks: $($j-1)"

		for ($l = 1; $l -le $($j-1); $l++){ #Parse through each drive
				$vdiskName = (Get-SNMP $ip "$virtualDiskName.$l" $comm).Data
				$vdiskStatus = (Get-SNMP $ip "$virtualDiskState.$l" $comm).Data
				$vdiskCapacityInMB = (Get-SNMP $ip "$virtualDiskSizeInMB.$l" $comm).Data
				$vdiskLayout = (Get-SNMP $ip "$virtualDiskLayout.$l" $comm).Data
				Write-Verbose "Virtual Disk: $vdiskName | Status: $($vstates.Item([Int32]$vdiskStatus)) | RAID: $($raid.Item([Int32]$vdiskLayout)) | Capacity (MB): $vdiskCapacityInMB"
							
		}
		
		Write-Verbose ""
		Write-Verbose ""

}



function Get-HardwareType([string]$ip, [string]$comm = "public", [int]$port=161, [int]$timeout=3000){
		
		#
		# Checks the system model for the OMSA and the iDRAC systems to determine which one it is
		# OMSA - returns 1
		# iDRAC - returns 2
		# Unknown - returns 0
		#
		
		$systemType = 0
		#### Combine these into a single if-elseif-else?
		
		#Verify hardware is Dell, and check whether it's an iDRAC or OpenManage
		$chassisModelNameOMSA = '1.3.6.1.4.1.674.10892.1.300.10.1.9.1'
		$snmp_out = (Get-SNMP -sIP $ip -sOIDs $chassisModelNameOMSA -Community $comm -UDPPort $port -TimeOut $timeout).Data
		If($snmp_out -contains "NoSuchObject") { #Not an OMSA device
			#Do I need to do anything if it's NOT an OMSA?
		}
		Else {
			$systemType = 1
			$global:model = $snmp_out
		}
		
		$chassisModelNameiDRAC = '1.3.6.1.4.1.674.10892.5.1.3.12.0'
		$snmp_out = (Get-SNMP -sIP $ip -sOIDs $chassisModelNameiDRAC -Community $comm -UDPPort $port -Timeout $timeout).Data
		If($snmp_out -contains "NoSuchObject") { #Not an OMSA device
			#Do I need to do anything if it's NOT an iDRAC?
		}
		Else {
			$systemType= 2
			$global:model = $snmp_out
		}


		return $systemType
		
		

}


#Get SNMP
function Get-SNMP ([string]$sIP, $sOIDs, [string]$Community = "public", [int]$UDPport = 161, [int]$TimeOut=3000) {
    # $OIDs can be a single OID string, or an array of OID strings
    # $TimeOut is in msec, 0 or -1 for infinite

    # Create OID variable list
    
	If($PSVersionTable.PSVersion.Major -gt 2){
		$vList = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'                          # PowerShell v3 and above
	}
	Else{
		$vList = New-GenericObject System.Collections.Generic.List Lextm.SharpSnmpLib.Variable                   # PowerShell v1 and v2
	}
    
    foreach ($sOID in $sOIDs) {
        $oid = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($sOID)
        $vList.Add($oid)
    }
    
    # Create endpoint for SNMP server
    $ip = [System.Net.IPAddress]::Parse($sIP)
    $svr = New-Object System.Net.IpEndPoint ($ip, 161)
    
    # Use SNMP v2
    $ver = [Lextm.SharpSnmpLib.VersionCode]::V2
    
    # Perform SNMP Get
    #try {
        $msg = [Lextm.SharpSnmpLib.Messaging.Messenger]::Get($ver, $svr, $Community, $vList, $TimeOut)
    #} catch {
    #Write-Host "SNMP Get error: $_"
     #   Return $null
    #}
    
    $res = @()
    foreach ($var in $msg) {
        $line = "" | Select OID, Data
        $line.OID = $var.Id.ToString()
        $line.Data = $var.Data.ToString()
        $res += $line
    }
    
    $res
}
