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
#	Short URL: https://goo.gl/uIVXKD							                    #
#	(new-object Net.WebClient).DownloadString('https://goo.gl/uIVXKD') | iex				    #
#														    #
#####################################################################################################################

#Set path for the Sharp SNMP library DLL file. Change this if you want to store it somewhere else
$snmplibpath = "C:\SharpSNMP\SharpSnmpLib.dll"

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
	
				1 { $globalSystemStatus = ".1.3.6.1.4.1.674.10892.1.300.10.1.4.1"	
						$systemVersion = ".1.3.6.1.4.1.674.10892.1.100.10.0"
						
						}
				2 { $globalSystemStatus = "1.3.6.1.4.1.674.10892.5.4.200.10.1.2.1" 
						$systemVersion = ".1.3.6.1.4.1.674.10892.5.1.1.2.0"
				}
	}
	
	$snmpCheck = (Get-SNMP  $IP  $globalSystemStatus  $Comm $port $timeout).Data
	$systemType = (Get-SNMP $IP $systemVersion $Comm $port $timeout).Data
	if($type -eq 1) { $systemType = "OMSA $systemType"}
	switch ($snmpCheck){
		
		$OTHER	{Write-Host "WARNING:" $model "|" $systemType}
		$UNKNOWN {Write-Host "WARNING:" $model "|" $systemType}
		$OK	{Write-Host "OK:" $model "|" $systemType}
		$WARNING {Write-Host "WARNING:" $model "|" $systemType}
		$CRITICAL {Write-Host "CRITICAL:" $model "|" $systemType}
		default {Write-Host "Error: " $snmpCheck "|" $systemType}
			
		}
		
		if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent){
			Get-DellStorageStatus $IP $Comm
			Get-DellBatteryStatus $IP $Comm
		
		
		}
		
}
function Get-DellStorageStatus([string]$ip,[string]$comm = "public", [int]$port=161, [int]$timeout=3000){
		
		Write-Verbose "-----Storage Status-----"
		
$idracstates = @{
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
	
$idracvstates = @{
	1 = "Unknown";
	2 = "Online";
	3 = "Failed";
	4 = "Degraded";
}
	
$idracraid = @{
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
		
$omsastates = @{
	0 = "Unknown";
	1 = "Ready";
	2 = "Failed";
	3 = "Online";
	4 = "Offline";
	6 = "Degraded";
	7 = "Recovering";
	11 = "Removed";
	13 = "Non-RAID";
	14 = "Not Ready";
	15 = "Resynching";
	22 = "Replacing";
	23 = "Spinning Down";
	24 = "Rebuilding";
	25 = "No Media";
	26 = "Formatting";
	28 = "Diagnostics";
	34 = "Predictive Failure";
	35 = "Initializing";
	39 = "Foreign";
	40 = "Clear";
	41 = "Unsupported";
	53 = "Incompatible";
	56 = "Read Only";
	
}		

$omsavstates = @{
	0 = "Unknown";
	1 = "Ready";
	2 = "Failed";
	3 = "Online";
	4 = "Offline";
	6 = "Degraded";
	15 = "Resynching";
	16 = "Regenerating";
	24 = "Rebuilding";
	26 = "Formatting";
	32 = "Reconstructing";
	35 = "Initializing";
	36 = "Background Initialization";
	38 = "Resynching Paused";
	52 = "Permanently Degraded";
	54 = "Degraded Redundancy";
}		

$omsaraid = @{
	1 = "Concatenated";
	2 = "RAID-0";
	3 = "RAID-1";
	7 = "RAID-5";
	8 = "RAID-6";
	10 = "RAID-10";
	12 = "RAID-50";
	19 = "Concatenated RAID-1";
	24 = "RAID-60";
	25 = "CacheCade";

}
		
	
	switch($type){
		
					1 { $enclosureDriveCount = ""
							$physicalDiskNumber = ".1.3.6.1.4.1.674.10893.1.20.130.4.1.1"
							$physicalDiskName = ".1.3.6.1.4.1.674.10893.1.20.130.4.1.2"
							$physicalDiskProductID = "1.3.6.1.4.1.674.10893.1.20.130.4.1.6"
							$physicalDiskState = ".1.3.6.1.4.1.674.10893.1.20.130.4.1.4"
							$physicalDiskCapacityInMB = ".1.3.6.1.4.1.674.10893.1.20.130.4.1.11"
							$virtualDiskNumber = ".1.3.6.1.4.1.674.10893.1.20.140.1.1.1"
							$virtualDiskName = ".1.3.6.1.4.1.674.10893.1.20.140.1.1.2"
							$virtualDiskState = ".1.3.6.1.4.1.674.10893.1.20.140.1.1.4"
							$virtualDiskLayout = ".1.3.6.1.4.1.674.10893.1.20.140.1.1.13"
							$virtualDiskSizeInMB = ".1.3.6.1.4.1.674.10893.1.20.140.1.1.6"
							$states = $omsastates ; $vstates = $omsavstates ; $raid = $omsaraid #Sets the appropriate tables for the type of connection
							}
					2 { $enclosureDriveCount = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.3.1.31.1"
							$physicalDiskNumber = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.1"
							$physicalDiskName = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.2"
							$physicalDiskProductID = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.6"
							$physicalDiskState = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.4"
							$physicalDiskCapacityInMB = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.11"
							$virtualDiskNumber = ".1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.1"
							$virtualDiskName = ".1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.2"
							$virtualDiskState = ".1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.4"
							$virtualDiskLayout = ".1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.13"
							$virtualDiskSizeInMB = ".1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.6"
							$states = $idracstates ; $vstates = $idracvstates ; $raid = $idracraid #Sets the appropriate tables for the type of connection
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
				$diskProductID = (Get-SNMP $ip "$physicalDiskProductID.$i" $comm).Data
				$diskStatus = (Get-SNMP $ip "$physicalDiskState.$i" $comm).Data
				$diskCapacityInMB = (Get-SNMP $ip "$physicalDiskCapacityInMB.$i" $comm).Data
				Write-Verbose "$diskName | Status: $($states.Item([Int32]$diskStatus)) | Capacity (GB): $($diskCapacityInMB/1024) | Model: $diskProductID"
							
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
				Write-Verbose "Virtual Disk: $vdiskName | Status: $($vstates.Item([Int32]$vdiskStatus)) | $($raid.Item([Int32]$vdiskLayout)) | Capacity (GB): $($vdiskCapacityInMB/1024)"
							
		}
		
		Write-Verbose ""
		

}
function Get-DellMemoryStatus([string]$ip,[string]$comm = "public", [int]$port=161, [int]$timeout=3000){
}
function Get-DellFanStatus([string]$ip,[string]$comm = "public", [int]$port=161, [int]$timeout=3000){
}
function Get-DellPowerStatus([string]$ip,[string]$comm = "public", [int]$port=161, [int]$timeout=3000){
}
function Get-DellCPUStatus([string]$ip,[string]$comm = "public", [int]$port=161, [int]$timeout=3000){
}
function Get-DellTempStatus([string]$ip,[string]$comm = "public", [int]$port=161, [int]$timeout=3000){
}
function Get-DellBatteryStatus([string]$ip,[string]$comm = "public", [int]$port=161, [int]$timeout=3000){

	Write-Verbose "-----Battery Status-----"

$omsabattstates = @{
	0 = "Unknown";
	1 = "Ready";
	2 = "Failed";
	6 = "Degraded";
	7 = "Reconditioning";
	9 = "High";
	10 = "Power Low";
	12 = "Charging";
	21 = "Missing";
	36 = "Learning";
		
}

$idracbattstates = @{
	1 = "Unknown";
	2 = "Ready";
	3 = "Failed";
	4 = "Degraded";
	5 = "Missing";
	6 = "Charging";
	7 = "Below Threshold";
}

		switch($type){
				
							1 { 
									$batteryState = ".1.3.6.1.4.1.674.10893.1.20.130.15.1.4"
									$batteryDisplayName = ".1.3.6.1.4.1.674.10892.1.20.130.15.1.21.1"
									$battstates = $omsabattstates
									}
							2 { 
									$batteryState = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.15.1.4"
									$batteryDisplayName = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.15.1.21.1"
									$battstates = $idracbattstates
								}
								
				}
		$j=0
		Do {
			Try {
				$j=$j+1
				$snmp_out =  (Get-SNMP $IP "$batteryState.$j" $comm $port).Data
			}
			Catch {
				$snmp_out = ""
			}
			
		} Until(($snmp_out -contains "NoSuchInstance") -or ([string]::IsNullOrEmpty($snmp_out)))

		if($j -eq 1){
			Write-Verbose "No Controller Battery Detected"
		}
		Else{
				for ($l = 1; $l -le $($j-1); $l++){ #Parse through each battery
						$battName = (Get-SNMP $ip "$batteryDisplayName" $comm).Data
						$battStatus = (Get-SNMP $ip "$batteryState.1" $comm).Data
						
						Write-Verbose "$battName | Status: $($battstates.Item([Int32]$battStatus))"
				}
		}
		
		Write-Verbose ""

}
function Get-DellIntrusionStatus([string]$ip,[string]$comm = "public", [int]$port=161, [int]$timeout=3000){
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
