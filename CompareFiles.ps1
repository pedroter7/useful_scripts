<#
.SYNOPSIS
	Checks if files with the same name in two different directories are the same.
	
.DESCRIPTION 
	Checks if files with the same name in two different directories are the same. By default ignores files that don't exist in both directories.
	The comparison is made via file hash values.

.PARAMETER Dir1
	Directory where files that will be compared to are.
	
.PARAMETER Dir2
	Directory where files that will be compared with are.
	
.PARAMETER DontIgnore
	If this is set, the comparison will fail if one or more files don't exist in both directories.
	
.PARAMETER SupressWriteHost
	If this is set, the script won't use Write-Host to write the results.
	
.OUTPUTS
	$False or $True. Exit codes are 0 for true and 1 for false.

.NOTES
	Author: Pedro T Freidinger
#>

param (
	[Parameter(Mandatory=$true)][string]$Dir1,
	[Parameter(Mandatory=$true)][string]$Dir2,
	[switch]$DontIgnore=$False,
	[switch]$SupressWriteHost=$False
)

[array]$filesDir1 = Get-ChildItem -File $Dir1

foreach ($file in $filesDir1) {
	[string]$fname = $file.Name
	
	if (!(Test-Path -Path "$Dir2\$fname")) {
		if ($DontIgnore {
			if (!$SupressWriteHost) {
				Write-Host "$Dir2\$fname does not exist." -foreground 'red'
			}
			Write-Output $False
			Exit 1
		}
		if (!$SupressWriteHost) {
			write-host "$Dir2\$fname does not exist. Ignoring..." -foreground 'yellow'
		}
	} else {
		
		[string]$hash1 = (Get-FileHash "$Dir1\$fname").Hash
		[string]$hash2 = (Get-FileHash "$Dir2\$fname").Hash
	
		if ($hash1 -ne $hash2) {
			if (!$SupressWriteHost) {
				write-host "$Dir1\$fname not the same as $Dir2\$fname" -foreground 'red'
			}
			Write-Output $False
			Exit 1
		}
	}
}

if (!$SupressWriteHost) {
	write-host "All files from $Dir1 and $Dir2 are the same." -foreground 'green'
}
Write-Output $True
Exit 0