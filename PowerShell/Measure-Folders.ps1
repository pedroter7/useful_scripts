<#
.NOTES
Author: Pedro T Freidinger (pedrotersetti3@gmail.com)
License: MIT (github.com/pedroter7/useful_scripts)

In some cases the script may throw a
"Cannot process argument because the value of argument "Property" is not valid. Change the value of the "Property" argument and run the operation again."
But that's not a problem.

.SYNOPSIS

Measures the disk usage of folders in a given directory.

.DESCRIPTION

This script recurses through folders to find out how much disk space each folders occupies. By default it scans the current directory.

.PARAMETER Dir
Specifies the root directory for the scan. The default is the current directory.

.PARAMETER IgnoreHardLinks
If this flag is set then hard links are ignored. With this set the scan is more precise but slower.

.PARAMETER Sort
If this flag is set the output is sorted.

.OUTPUTS

System.Collections.ArrayList of Folder objects.
#>

param ([string]$Dir='.', [switch]$IgnoreHardLinks=$false, [switch]$Sort=$false)

class Folder{
    [string]$Name
    [string]$FullPath
    [double]$Size

    Folder([string]$fullPath, [double]$size) {
        $this.FullPath = $fullPath
        $this.Name = $fullPath.split('\')[-1]
        $this.Size = $size
    }
}

function Get-FoldersInCurrentDir([string]$currentDir) {
    [array]$folders = Get-ChildItem -Path $currentDir -Directory -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    return $folders
}

function Measure-FolderSize([string]$folderPath, [bool]$ignoreHardLinks) {
    [array]$allObjects = Get-ChildItem -Path $folderPath -Recurse -Force -ErrorAction SilentlyContinue
    if ($ignoreHardLinks) {
        $allObjects = $allObjects | Where-Object { $_.LinkType -notmatch 'HardLink'}
    }
    [double]$size = ($allObjects | Measure-Object -Property Length -Sum).sum / 1Mb
    return $size
}

[System.Collections.ArrayList]$folderObjects = [System.Collections.ArrayList]::New()
[array]$foldersInCurrentDir = Get-FoldersInCurrentDir $Dir

foreach ($folderPath in $foldersInCurrentDir) {
    [double]$folderSize = Measure-FolderSize $folderPath $IgnoreHardLinks
    $null = $folderObjects.add([Folder]::New($folderPath, $folderSize))
}

if ($Sort) {
    Write-Output ($folderObjects | Sort-Object -Property Size)
} else {
    Write-Output $folderObjects
}