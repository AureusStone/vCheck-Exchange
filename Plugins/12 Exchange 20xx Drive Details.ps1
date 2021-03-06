$Title = "Exchange 20xx Drive Details"
$Header = "Exchange 20xx Drive Details"
$Comments = "Exchange 20xx Drive Details"
$Display = "Table"
$Author = "Phil Randal"
$PluginVersion = 2.2
$PluginCategory = "Exchange2010"

# Based on http://www.mikepfeiffer.net/2010/03/exchange-2010-database-statistics-with-powershell/

# Start of Settings
# Report Details only for drives with <= x% free space
$ReportPercent =100
# Mark drives with <= x% free space in red
$CriticalPercent =10
# End of Settings

# Changelog
## 2.0 : Exchange 2007 support
##       Add config option to report only on drives with <= x% free space
## 2.1 : Add Server name filter
## 2.2 : Colour critical values in red

If ($2007Snapin -or $2010Snapin) {
  $red="<font color='#FF0000'>"
  $fe="</font>"
  $exServers = Get-ExchangeServer -ErrorAction SilentlyContinue |
    Where { $_.IsExchange2007OrLater -eq $True -and $_.Name -match $exServerFilter } |
	Sort Name
  Foreach ($s in $exServers) {
	$Target = $s.Name
    Write-CustomOut "...Collating Drive Details for $Target"
	$Disks = Get-WmiObject -ComputerName $Target Win32_Volume | sort Name
	$LogicalDrives = @()
	Foreach ($LDrive in ($Disks | Where {$_.DriveType -eq 3 -and $_.Label -ne "System Reserved"})) {
	  $Details = "" | Select "Name", Label, "File System", "Capacity (GB)", "Free Space", "% Free Space"
	  $FreePercent = [Math]::Round(($LDrive.FreeSpace / 1GB) / ($LDrive.Capacity / 1GB) * 100)
	  if ($FreePercent -lt $CriticalPercent) {
	    $Details."Name" = $red + $LDrive.Name + $fe
	    $Details.Label = $red + $LDrive.Label + $fe
	    $Details."File System" = $red + $LDrive.FileSystem + $fe
  	    $Details."Capacity (GB)" = $red + ([math]::round(($LDrive.Capacity / 1GB))).toString() + $fe
	    $Details."Free Space" = $red + ([math]::round(($LDrive.FreeSpace / 1GB))).toString() + $fe
	    $Details."% Free Space" = $red + $FreePercent.toString() + $fe
	  } Else {
	    $Details."Name" = $LDrive.Name
	    $Details.Label = $LDrive.Label
	    $Details."File System" = $LDrive.FileSystem
  	    $Details."Capacity (GB)" = ([math]::round(($LDrive.Capacity / 1GB))).toString()
	    $Details."Free Space" = ([math]::round(($LDrive.FreeSpace / 1GB))).toString()
	    $Details."% Free Space" = $FreePercent.toString()
	  }
	  If ($FreePercent -le $ReportPercent) {
 	    $LogicalDrives += $Details
	  }
	}
	If ($LogicalDrives.Count -gt 0) {
	  $Comments = "Drives on Exchange Server $Target"
	  If ($ReportPercent -lt 100) {
	    $Comments += " with less than $($ReportPercent)% free space"
      }
	  $Header = $Comments
      $script:MyReport += Get-CustomHeader $Header $Comments
	  $script:MyReport += Get-HTMLTable $LogicalDrives
      $script:MyReport += Get-CustomHeaderClose
	}
  }
  $Details = $null
  $LogicalDrives = $null
  $Comments = "Exchange 20xx Drive Details"
}
